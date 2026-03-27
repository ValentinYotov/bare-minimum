<?php
/**
 * Payload for the Recommendations UI and JSON API.
 * Shape matches ai_services/recommendations/get_recommendations.py (SensorReading + RecommendationResponse).
 * When NPK hardware posts readings, set ssws_recommendations_use_mock_data() to false and load from DB/API.
 */
require_once __DIR__ . "/zone_rules.php";
require_once __DIR__ . "/../ssws_paths.php";
require_once __DIR__ . "/crop_image_registry.php";

/**
 * Image URL for a crop name from crop_image_registry.json (data-only mapping; no crop list in PHP).
 * Local files use "file" paths; optional "unsplash" in JSON is for download_crop_images_from_registry.php.
 */
function ssws_recommendations_crop_image_url(string $cropName): string
{
    $u = ssws_crop_resolve_image_url($cropName);
    if (
        strpos($u, "http://") !== 0
        && strpos($u, "https://") !== 0
        && strpos($u, "//") !== 0
    ) {
        return ssws_url(ltrim($u, "/"));
    }
    return $u;
}

/**
 * @param list<array<string, mixed>> $recs
 * @return list<array<string, mixed>>
 */
function ssws_recommendations_enrich_images(array $recs): array
{
    $out = [];
    foreach ($recs as $r) {
        if (!empty($r["image_url"])) {
            $u = (string) $r["image_url"];
            if (
                strpos($u, "http://") !== 0
                && strpos($u, "https://") !== 0
                && strpos($u, "//") !== 0
            ) {
                $r["image_url"] = ssws_url(ltrim($u, "/"));
            }
        } else {
            $r["image_url"] = ssws_recommendations_crop_image_url((string) ($r["crop"] ?? ""));
        }
        $out[] = $r;
    }
    return $out;
}

function ssws_recommendations_use_mock_data(): bool
{
    return true;
}

/**
 * @return array<string, mixed>
 */
function ssws_recommendations_mock_response_body(): array
{
    return [
        "recommendations" => [
            [
                "crop" => "Maize",
                "confidence" => "high",
                "reasoning" =>
                    "N-P-K and pH sit close to profiles where maize yielded well in the reference dataset. EC is moderate, so salinity is unlikely to limit germination.",
            ],
            [
                "crop" => "Sunflower",
                "confidence" => "high",
                "reasoning" =>
                    "Potassium is adequate for stalk strength; pH is in a band sunflower tolerates. Good fit if rotation requires a broadleaf break crop.",
            ],
            [
                "crop" => "Soybeans",
                "confidence" => "medium",
                "reasoning" =>
                    "Phosphorus is sufficient for nodulation, though you may monitor K if biomass is heavy. Consider inoculant if soybeans are new to the field.",
            ],
            [
                "crop" => "Winter wheat",
                "confidence" => "medium",
                "reasoning" =>
                    "Soil reaction is acceptable for wheat; nitrogen may need split application to match yield targets. Works well after a legume or if following maize.",
            ],
        ],
        "data_source" => "dataset+general_knowledge",
        "retrieved_profiles_used" => 12,
        "notes" => null,
    ];
}

/**
 * @return array<string, mixed>
 */
function ssws_recommendations_mock_reading_for_zone(string $zoneKey, string $zoneLabel): array
{
    return [
        "zone_key" => $zoneKey,
        "zone_label" => $zoneLabel,
        "updated_at" => gmdate("c"),
        "N" => 95.0,
        "P" => 48.0,
        "K" => 52.0,
        "ph" => 6.45,
        "humidity" => 62.5,
        "electrical_conductivity" => 0.85,
    ];
}

/**
 * @return array{
 *   is_mock: bool,
 *   reading: array<string, mixed>,
 *   recommendations: list<array{crop: string, confidence: string, reasoning: string}>,
 *   data_source: string,
 *   retrieved_profiles_used: int,
 *   notes: string|null
 * }
 */
function ssws_recommendations_payload(mysqli $conn, string $username): array
{
    $rules = ssws_load_all_zone_rules($conn, $username);
    $zoneKey = "field";
    $zoneLabel = "Primary zone";
    foreach ($rules as $k => $r) {
        $zoneKey = $k;
        $dn = trim((string) ($r["display_name"] ?? ""));
        $zoneLabel = $dn !== "" ? $dn : str_replace("_", " ", (string) $k);
        break;
    }

    if (ssws_recommendations_use_mock_data()) {
        $body = ssws_recommendations_mock_response_body();
        return [
            "is_mock" => true,
            "reading" => ssws_recommendations_mock_reading_for_zone($zoneKey, $zoneLabel),
            "recommendations" => ssws_recommendations_enrich_images($body["recommendations"]),
            "data_source" => $body["data_source"],
            "retrieved_profiles_used" => $body["retrieved_profiles_used"],
            "notes" => $body["notes"],
        ];
    }

    // Placeholder for live pipeline (sensor POSTs + optional Python service).
    return [
        "is_mock" => false,
        "reading" => ssws_recommendations_mock_reading_for_zone($zoneKey, $zoneLabel),
        "recommendations" => ssws_recommendations_enrich_images([]),
        "data_source" => "none",
        "retrieved_profiles_used" => 0,
        "notes" => "Live NPK data not wired yet.",
    ];
}
