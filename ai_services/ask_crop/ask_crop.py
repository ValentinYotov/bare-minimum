import json
import os
from contextlib import asynccontextmanager

import numpy as np
import openai
import pandas as pd
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", ".env"))

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
CSV_PATH = os.path.join(os.path.dirname(__file__), "..", "Crop_recommendation.csv")
RESULTS_FILE = os.path.join(os.path.dirname(__file__), "ask_crop_result.txt")
OPENAI_MODEL = "gpt-4o-mini"

SYSTEM_PROMPT = """You are an expert agronomist. You will be given:
1. The user's current soil sensor readings.
2. Either ideal soil parameter ranges from a validated crop dataset, OR a note that the plant is not in the dataset.
3. A compatibility score (0-100) for each parameter (only when dataset data is available).

Your task: assess how suitable the current soil is for growing that plant, and recommend what to change.

Rules:
- If the input is not a real plant (e.g. a random word, an animal, an object), return {"not_a_plant": true} and nothing else.
- If dataset data is available, use it to estimate the probability range and adjustments.
- If the plant is not in the dataset, use your general agronomic knowledge to determine ideal ranges and assess compatibility.
- For each parameter that is not optimal, give a concrete, specific adjustment recommendation.
- If a parameter is optimal, set status to "optimal" and adjustment to "No change needed".
- Be honest: if the soil is very far from ideal, reflect that in the probability.
- Return ONLY valid JSON with this exact structure, no markdown fences:
  {
    "plant": "...",
    "probability_range": "X-Y%",
    "overall_assessment": "...",
    "adjustments": [
      {
        "parameter": "...",
        "current_value": <float>,
        "ideal_min": <float>,
        "ideal_max": <float>,
        "status": "deficient|excess|optimal",
        "adjustment": "..."
      }
    ],
    "notes": "..."|null
  }"""


# ---------------------------------------------------------------------------
# Pydantic models
# ---------------------------------------------------------------------------

class PlantGrowthRequest(BaseModel):
    N: float = Field(..., ge=0, description="Nitrogen content in soil (kg/ha)")
    P: float = Field(..., ge=0, description="Phosphorus content in soil (kg/ha)")
    K: float = Field(..., ge=0, description="Potassium content in soil (kg/ha)")
    ph: float = Field(..., ge=0, le=14, description="Soil pH")
    humidity: float = Field(..., ge=0, le=100, description="Relative humidity (%)")
    electrical_conductivity: float = Field(..., ge=0, description="Soil electrical conductivity (mS/cm)")
    plant: str = Field(..., description="Name of the plant the user wants to grow")


class SoilAdjustment(BaseModel):
    parameter: str
    current_value: float
    ideal_min: float
    ideal_max: float
    status: str       # "deficient" | "excess" | "optimal"
    adjustment: str


class PlantGrowthResponse(BaseModel):
    plant: str
    probability_range: str | None = None
    overall_assessment: str | None = None
    adjustments: list[SoilAdjustment] | None = None
    notes: str | None = None
    error: str | None = None


# ---------------------------------------------------------------------------
# Dataset helpers
# ---------------------------------------------------------------------------

def _get_plant_stats(plant_name: str) -> dict:
    df = pd.read_csv(CSV_PATH)
    available = df["label"].str.lower().unique().tolist()

    match = next((p for p in available if p == plant_name.lower()), None)
    if match is None:
        match = next((p for p in available if plant_name.lower() in p or p in plant_name.lower()), None)
    if match is None:
        # Not in dataset — LLM will use general knowledge
        return {"plant_name": plant_name.lower(), "in_dataset": False}

    plant_df = df[df["label"].str.lower() == match]
    features = ["N", "P", "K", "ph", "humidity"]
    stats = {"plant_name": match, "in_dataset": True, "sample_count": len(plant_df), "features": {}}

    for feat in features:
        values = plant_df[feat]
        stats["features"][feat] = {
            "mean": round(float(values.mean()), 2),
            "std": round(float(values.std()), 2),
            "ideal_min": round(float(values.quantile(0.10)), 2),
            "ideal_max": round(float(values.quantile(0.90)), 2),
        }

    return stats


def _score_parameter(value: float, ideal_min: float, ideal_max: float, std: float) -> int:
    """Returns 0-100: 100 if within ideal range, decays with distance outside."""
    if ideal_min <= value <= ideal_max:
        return 100
    deviation = max(ideal_min - value, value - ideal_max)
    penalty = min(deviation / (std + 1e-8), 3.0) / 3.0
    return max(0, round(100 * (1 - penalty)))


def _get_status(value: float, ideal_min: float, ideal_max: float) -> str:
    if value < ideal_min:
        return "deficient"
    if value > ideal_max:
        return "excess"
    return "optimal"


# ---------------------------------------------------------------------------
# LLM call
# ---------------------------------------------------------------------------

def _get_recommendation(request: PlantGrowthRequest, stats: dict) -> dict:
    sensor_text = (
        f"CURRENT SENSOR READINGS:\n"
        f"  Nitrogen (N): {request.N} kg/ha\n"
        f"  Phosphorus (P): {request.P} kg/ha\n"
        f"  Potassium (K): {request.K} kg/ha\n"
        f"  Soil pH: {request.ph}\n"
        f"  Humidity: {request.humidity}%\n"
        f"  Electrical Conductivity (EC): {request.electrical_conductivity} mS/cm\n"
    )

    if stats.get("in_dataset"):
        features = stats["features"]
        sensor = {"N": request.N, "P": request.P, "K": request.K, "ph": request.ph, "humidity": request.humidity}
        scores_text = "\n".join(
            f"  {feat}: current={sensor[feat]}, "
            f"ideal={features[feat]['ideal_min']}-{features[feat]['ideal_max']}, "
            f"status={_get_status(sensor[feat], features[feat]['ideal_min'], features[feat]['ideal_max'])}, "
            f"score={_score_parameter(sensor[feat], features[feat]['ideal_min'], features[feat]['ideal_max'], features[feat]['std'])}/100"
            for feat in features
        )
        overall_score = round(
            sum(_score_parameter(sensor[f], features[f]["ideal_min"], features[f]["ideal_max"], features[f]["std"]) for f in features)
            / len(features)
        )
        user_message = (
            f"TARGET PLANT: {stats['plant_name']} (from {stats['sample_count']} dataset samples)\n\n"
            + sensor_text +
            f"\nPARAMETER ANALYSIS (ideal = 10th-90th percentile from dataset):\n"
            f"{scores_text}\n\n"
            f"OVERALL COMPATIBILITY SCORE: {overall_score}/100\n\n"
            f"Provide the growth probability and soil adjustment recommendations."
        )
    else:
        user_message = (
            f"TARGET PLANT: {stats['plant_name']} (not in dataset — use general agronomic knowledge)\n\n"
            + sensor_text +
            f"\nThe plant is not in the dataset. Use your general knowledge to assess compatibility "
            f"and recommend soil adjustments. If '{stats['plant_name']}' is not a real plant, "
            f"return {{\"not_a_plant\": true}}."
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
            temperature=0.3,
            max_tokens=1000,
        ).choices[0].message.content
    )

    return result


# ---------------------------------------------------------------------------
# File output
# ---------------------------------------------------------------------------

def _save_to_file(request: PlantGrowthRequest, response: PlantGrowthResponse) -> None:
    with open(RESULTS_FILE, "w", encoding="utf-8") as f:
        f.write("=" * 80 + "\n")
        f.write(f"PLANT GROWTH COMPATIBILITY: {response.plant.upper()}\n")
        f.write("=" * 80 + "\n\n")

        if response.error:
            f.write(f"Error: {response.error}\n")
            f.write("=" * 80 + "\n")
            return

        f.write("SENSOR READINGS:\n")
        f.write(f"  Nitrogen (N):               {request.N} kg/ha\n")
        f.write(f"  Phosphorus (P):             {request.P} kg/ha\n")
        f.write(f"  Potassium (K):              {request.K} kg/ha\n")
        f.write(f"  Soil pH:                    {request.ph}\n")
        f.write(f"  Humidity:                   {request.humidity}%\n")
        f.write(f"  Electrical Conductivity:    {request.electrical_conductivity} mS/cm\n\n")

        f.write(f"GROWTH PROBABILITY:  {response.probability_range}\n")
        f.write(f"ASSESSMENT: {response.overall_assessment}\n\n")

        f.write("SOIL ADJUSTMENTS:\n")
        f.write("-" * 80 + "\n")
        for adj in response.adjustments:
            marker = "✓" if adj.status == "optimal" else "✗"
            f.write(
                f"{marker} {adj.parameter.upper()}: {adj.current_value} "
                f"(ideal: {adj.ideal_min} - {adj.ideal_max}) [{adj.status}]\n"
            )
            f.write(f"   → {adj.adjustment}\n\n")

        if response.notes:
            f.write(f"NOTES: {response.notes}\n")
        f.write("=" * 80 + "\n")


# ---------------------------------------------------------------------------
# FastAPI app
# ---------------------------------------------------------------------------

app = FastAPI(title="Ask Crop Service")


@app.post("/plant-growth", response_model=PlantGrowthResponse)
async def plant_growth(request: PlantGrowthRequest):
    stats = _get_plant_stats(request.plant)
    try:
        raw = _get_recommendation(request, stats)
        if raw.get("not_a_plant"):
            response = PlantGrowthResponse(
                plant=request.plant,
                error=f"'{request.plant}' is not a valid plant."
            )
        else:
            response = PlantGrowthResponse(**raw)
        _save_to_file(request, response)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
