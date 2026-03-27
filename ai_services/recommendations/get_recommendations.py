import json
import os
from contextlib import asynccontextmanager

import chromadb
import numpy as np
import openai
import pandas as pd
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", ".env"))

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
CHROMA_PERSIST_DIR = os.path.join(os.path.dirname(__file__), "chroma_db")
# v2: uses numeric embeddings instead of text embeddings — forces re-ingestion
COLLECTION_NAME = "crop_profiles_v3"
CSV_PATH = os.path.join(os.path.dirname(__file__), "..", "Crop_recommendation.csv")
RESULTS_FILE = os.path.join(os.path.dirname(__file__), "recommendations_result.txt")
TOP_K = 15
OPENAI_MODEL = "gpt-4o-mini"
FEATURE_COLS = ["N", "P", "K", "ph", "humidity"]

# Normalization stats populated at startup from CSV
_feat_mins: np.ndarray | None = None
_feat_maxs: np.ndarray | None = None

SYSTEM_PROMPT = """You are an expert agronomist for a smart irrigation system. You will be given:
1. Current soil sensor readings from the field.
2. A set of similar soil profiles retrieved from a validated crop recommendation dataset.

Your task: recommend the most suitable crops to grow given the sensor data.

Rules:
- Prioritize crops that appear in the retrieved dataset profiles.
- If no dataset profiles are relevant, fall back to general agronomic knowledge.
- The sensor does not report temperature or rainfall; use the retrieved profiles as a proxy for those conditions.
- The sensor reports electrical conductivity (EC); factor salinity tolerance into your reasoning when EC is notably high (above 2.0 mS/cm).
- IMPORTANT: You MUST recommend AT LEAST 3 crops and at most 5 crops, ordered by suitability (most suitable first).
- Return ONLY valid JSON with this exact structure, no markdown fences:
  {
    "crops": ["crop1", "crop2", "crop3"]
  }"""


# ---------------------------------------------------------------------------
# Pydantic models
# ---------------------------------------------------------------------------

class SensorReading(BaseModel):
    N: float = Field(..., ge=0, description="Nitrogen content in soil (kg/ha)")
    P: float = Field(..., ge=0, description="Phosphorus content in soil (kg/ha)")
    K: float = Field(..., ge=0, description="Potassium content in soil (kg/ha)")
    ph: float = Field(..., ge=0, le=14, description="Soil pH")
    humidity: float = Field(..., ge=0, le=100, description="Relative humidity (%)")
    electrical_conductivity: float = Field(..., ge=0, description="Soil electrical conductivity (mS/cm)")


class RecommendationResponse(BaseModel):
    crops: str  # semicolon-separated list


# ---------------------------------------------------------------------------
# ChromaDB setup and ingestion
# ---------------------------------------------------------------------------

def _make_embedding(feature_values: list[float]) -> list[float]:
    """Normalize feature values to [0, 1] using dataset min/max for cosine similarity."""
    arr = np.array(feature_values, dtype=float)
    normalized = (arr - _feat_mins) / (_feat_maxs - _feat_mins + 1e-8)
    return normalized.tolist()


def _load_normalization_stats(df: pd.DataFrame) -> None:
    global _feat_mins, _feat_maxs
    _feat_mins = df[FEATURE_COLS].min().values.astype(float)
    _feat_maxs = df[FEATURE_COLS].max().values.astype(float)


def _ingest_csv(collection: chromadb.Collection) -> None:
    df = pd.read_csv(CSV_PATH)
    _load_normalization_stats(df)

    documents, metadatas, ids, embeddings = [], [], [], []

    for idx, row in df.iterrows():
        documents.append(f"Recommended crop: {row['label']}")
        metadatas.append({
            "N": float(row["N"]),
            "P": float(row["P"]),
            "K": float(row["K"]),
            "temperature": float(row["temperature"]),
            "humidity": float(row["humidity"]),
            "ph": float(row["ph"]),
            "rainfall": float(row["rainfall"]),
            "label": str(row["label"]),
        })
        ids.append(str(idx))
        embeddings.append(_make_embedding([row[c] for c in FEATURE_COLS]))

    batch_size = 500
    for i in range(0, len(documents), batch_size):
        collection.add(
            documents=documents[i : i + batch_size],
            metadatas=metadatas[i : i + batch_size],
            ids=ids[i : i + batch_size],
            embeddings=embeddings[i : i + batch_size],
        )


def get_or_create_collection() -> chromadb.Collection:
    # Always load normalization stats from CSV (needed for query embeddings)
    df = pd.read_csv(CSV_PATH)
    _load_normalization_stats(df)

    client = chromadb.PersistentClient(path=CHROMA_PERSIST_DIR)
    collection = client.get_or_create_collection(
        name=COLLECTION_NAME,
        metadata={"hnsw:space": "cosine"},
        embedding_function=None,
    )
    if collection.count() == 0:
        _ingest_csv(collection)
    return collection


# ---------------------------------------------------------------------------
# Query and LLM call
# ---------------------------------------------------------------------------

def query_similar_profiles(collection: chromadb.Collection, reading: SensorReading) -> list[dict]:
    query_embedding = _make_embedding([reading.N, reading.P, reading.K, reading.ph, reading.humidity])
    results = collection.query(query_embeddings=[query_embedding], n_results=TOP_K)
    return results["metadatas"][0]


def get_llm_recommendation(reading: SensorReading, profiles: list[dict]) -> dict:
    profiles_text = "\n".join(
        f"  Profile {i + 1}: N={int(p['N'])}, P={int(p['P'])}, K={int(p['K'])}, "
        f"temp={p['temperature']:.1f}C, humidity={p['humidity']:.1f}%, "
        f"pH={p['ph']:.2f}, rainfall={p['rainfall']:.1f}mm → {p['label']}"
        for i, p in enumerate(profiles)
    )

    user_message = (
        f"SENSOR READINGS:\n"
        f"- Nitrogen (N): {int(reading.N)} kg/ha\n"
        f"- Phosphorus (P): {int(reading.P)} kg/ha\n"
        f"- Potassium (K): {int(reading.K)} kg/ha\n"
        f"- Soil pH: {reading.ph:.2f}\n"
        f"- Humidity: {reading.humidity:.1f}%\n"
        f"- Electrical Conductivity (EC): {reading.electrical_conductivity:.3f} mS/cm\n"
        f"\n"
        f"RETRIEVED DATASET PROFILES (top {len(profiles)} most similar soil profiles):\n"
        f"{profiles_text}\n"
        f"\n"
        f"Based on these profiles and sensor readings, provide your crop recommendations."
    )

    client = openai.OpenAI(api_key=OPENAI_API_KEY)
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_message},
    ]

    result = json.loads(client.chat.completions.create(
        model=OPENAI_MODEL,
        response_format={"type": "json_object"},
        messages=messages,
        temperature=0.5,
        max_tokens=200,
    ).choices[0].message.content)

    # Retry if fewer than 3 crops returned
    if len(result.get("crops", [])) < 3:
        messages.append({"role": "assistant", "content": json.dumps(result)})
        messages.append({
            "role": "user",
            "content": (
                f"You only returned {len(result.get('crops', []))} crop(s). "
                "You MUST return AT LEAST 3 crops. "
                "Add more using your general agronomic knowledge if needed."
            ),
        })
        result = json.loads(client.chat.completions.create(
            model=OPENAI_MODEL,
            response_format={"type": "json_object"},
            messages=messages,
            temperature=0.7,
            max_tokens=200,
        ).choices[0].message.content)

    return {"crops": ";".join(result.get("crops", []))}


# ---------------------------------------------------------------------------
# FastAPI app
# ---------------------------------------------------------------------------

collection: chromadb.Collection | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global collection
    collection = get_or_create_collection()
    yield


app = FastAPI(title="Crop Recommendation Service", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["POST", "GET", "OPTIONS"],
    allow_headers=["*"],
)


def _save_results_to_file(response: RecommendationResponse) -> None:
    with open(RESULTS_FILE, "w") as f:
        f.write(response.crops)


@app.post("/recommendations", response_model=RecommendationResponse)
async def recommend(reading: SensorReading):
    profiles = query_similar_profiles(collection, reading)
    try:
        raw = get_llm_recommendation(reading, profiles)
        response = RecommendationResponse(**raw)
        _save_results_to_file(response)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
