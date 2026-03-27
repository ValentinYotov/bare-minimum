import json
import os

import chromadb
import openai
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", ".env"))

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
CHROMA_PERSIST_DIR = os.path.join(os.path.dirname(__file__), "..", "recommendations", "chroma_db")
COLLECTION_NAME = "crop_profiles_v3"
RESULTS_FILE = os.path.join(os.path.dirname(__file__), "minimum_humidity_result.txt")
OPENAI_MODEL = "gpt-4o-mini"

SYSTEM_PROMPT = """You are an expert agronomist for a smart irrigation system.

Your task: determine the minimum soil humidity threshold below which a plant needs to be watered.

Rules:
- If dataset statistics are provided, use them to determine the threshold.
- If no dataset statistics are provided, use your general agronomic knowledge.
- If the input is not a real plant (e.g. a random word, an animal, an object), set minimum_humidity to -1.
- Return ONLY valid JSON with this exact structure, no markdown fences:
  {
    "plant": "...",
    "minimum_humidity": <float>
  }"""


# ---------------------------------------------------------------------------
# Pydantic models
# ---------------------------------------------------------------------------

class HumidityRequest(BaseModel):
    plant: str = Field(..., description="Name of the plant")


class HumidityResponse(BaseModel):
    plant: str
    minimum_humidity: float | None = None
    error: str | None = None


# ---------------------------------------------------------------------------
# ChromaDB query
# ---------------------------------------------------------------------------

def _get_plant_humidity_stats(plant_name: str) -> dict:
    client = chromadb.PersistentClient(path=CHROMA_PERSIST_DIR)
    collection = client.get_collection(name=COLLECTION_NAME, embedding_function=None)

    # Get all records for this plant from the vector database
    results = collection.get(
        where={"label": plant_name.lower()},
        include=["metadatas"],
    )

    if not results["metadatas"]:
        # Not in dataset — fall back to general knowledge
        return {"plant_name": plant_name.lower(), "in_dataset": False}

    humidity_values = [m["humidity"] for m in results["metadatas"]]
    humidity_values.sort()
    n = len(humidity_values)
    p10_index = max(0, int(n * 0.10) - 1)

    return {
        "plant_name": plant_name.lower(),
        "in_dataset": True,
        "sample_count": n,
        "humidity_min": round(min(humidity_values), 2),
        "humidity_p10": round(humidity_values[p10_index], 2),
        "humidity_mean": round(sum(humidity_values) / n, 2),
        "humidity_max": round(max(humidity_values), 2),
    }


# ---------------------------------------------------------------------------
# LLM call
# ---------------------------------------------------------------------------

def _get_minimum_humidity(plant_name: str, stats: dict) -> dict:
    if stats.get("in_dataset"):
        user_message = (
            f"PLANT: {stats['plant_name']}\n"
            f"HUMIDITY DATA FROM DATASET ({stats['sample_count']} samples):\n"
            f"  Minimum recorded:    {stats['humidity_min']}%\n"
            f"  10th percentile:     {stats['humidity_p10']}%\n"
            f"  Mean:                {stats['humidity_mean']}%\n"
            f"  Maximum recorded:    {stats['humidity_max']}%\n\n"
            f"Based on this data, what is the minimum humidity threshold below which "
            f"the watering system should activate for {stats['plant_name']}?"
        )
    else:
        user_message = (
            f"PLANT: {stats['plant_name']}\n"
            f"No dataset data available for this plant. "
            f"Use your general agronomic knowledge to determine the minimum soil humidity threshold "
            f"below which the watering system should activate. "
            f"If '{stats['plant_name']}' is not a real plant, set minimum_humidity to -1."
        )

    client = openai.OpenAI(api_key=OPENAI_API_KEY)
    result = json.loads(
        client.chat.completions.create(
            model=OPENAI_MODEL,
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": user_message},
            ],
            temperature=0.2,
            max_tokens=400,
        ).choices[0].message.content
    )
    return result


# ---------------------------------------------------------------------------
# File output
# ---------------------------------------------------------------------------

def _save_to_file(response: HumidityResponse) -> None:
    with open(RESULTS_FILE, "w", encoding="utf-8") as f:
        f.write(f"Plant: {response.plant}\n")
        if response.error:
            f.write(f"Error: {response.error}\n")
        else:
            f.write(f"Minimum humidity: {response.minimum_humidity}%\n")


# ---------------------------------------------------------------------------
# FastAPI app
# ---------------------------------------------------------------------------

app = FastAPI(title="Minimum Humidity Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/minimum-humidity", response_model=HumidityResponse)
async def minimum_humidity(request: HumidityRequest):
    stats = _get_plant_humidity_stats(request.plant)
    try:
        raw = _get_minimum_humidity(request.plant, stats)
        if raw.get("minimum_humidity") == -1:
            response = HumidityResponse(
                plant=request.plant,
                error=f"'{request.plant}' is not a valid plant."
            )
        else:
            response = HumidityResponse(**raw)
        _save_to_file(response)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
