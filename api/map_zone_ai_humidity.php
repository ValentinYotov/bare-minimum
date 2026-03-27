<?php
session_start();
header("Content-Type: application/json");

if (!isset($_SESSION["user"])) {
    http_response_code(401);
    echo json_encode(["ok" => false, "error" => "Unauthorized"]);
    exit;
}

require_once dirname(__DIR__) . "/config.php";
require_once dirname(__DIR__) . "/includes/domain/zone_rules.php";
require_once dirname(__DIR__) . "/includes/domain/crop_zone_humidity.php";

$user = $_SESSION["user"];

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    http_response_code(405);
    echo json_encode(["ok" => false, "error" => "Method not allowed"]);
    exit;
}

$raw = file_get_contents("php://input");
$body = json_decode((string) $raw, true);
if (!is_array($body)) {
    http_response_code(400);
    echo json_encode(["ok" => false, "error" => "Invalid JSON"]);
    exit;
}

$zoneKey = isset($body["zone_key"]) ? trim((string) $body["zone_key"]) : "";
if ($zoneKey === "" || !ssws_zone_key_valid($zoneKey)) {
    http_response_code(400);
    echo json_encode(["ok" => false, "error" => "Invalid zone_key"]);
    exit;
}

$rules = ssws_load_all_zone_rules($conn, $user);
if (!isset($rules[$zoneKey])) {
    http_response_code(404);
    echo json_encode(["ok" => false, "error" => "Zone not found"]);
    exit;
}

$r = $rules[$zoneKey];
$dn = trim((string) ($r["display_name"] ?? ""));
$zoneLabel = $dn !== "" ? $dn : str_replace("_", " ", $zoneKey);

$postHasPlanted = array_key_exists("planted_crop", $body);
$previewPlantedRaw = $postHasPlanted ? trim((string) ($body["planted_crop"] ?? "")) : null;
$previewPlanted = $previewPlantedRaw !== null && $previewPlantedRaw !== ""
    ? ssws_validate_planted_crop_label($previewPlantedRaw)
    : "";

$postHasDisplay = array_key_exists("display_name", $body);
$displayForGuess = $postHasDisplay
    ? trim((string) ($body["display_name"] ?? ""))
    : trim((string) ($r["display_name"] ?? ""));

$label = "";
$source = "";
$sim = null;

if ($previewPlanted !== "") {
    $label = $previewPlanted;
    $source = "Crop you selected (preview)";
} elseif (!$postHasPlanted) {
    $saved = ssws_validate_planted_crop_label(trim((string) ($r["planted_crop"] ?? "")));
    if ($saved !== "") {
        $label = $saved;
        $source = "Crop planted here (saved)";
    }
}

if ($label === "") {
    $guess = ssws_guess_crop_from_display_name($displayForGuess);
    if ($guess !== "") {
        $label = $guess;
        $source = "Matched from zone name";
    }
}

if ($label === "") {
    $reading = ssws_zone_reading_for_map_ai($conn, $user, $zoneKey, $zoneLabel);
    $nearest = ssws_nearest_dataset_crop_label($reading);
    if (isset($nearest["error"])) {
        echo json_encode([
            "ok" => false,
            "error" => $nearest["error"],
        ]);
        exit;
    }

    $label = $nearest["best_label"];
    $sim = $nearest["similarity"];
    $source = "Nearest soil profile (N, P, K, pH, humidity in dataset)";
}

$suggested = ssws_suggested_water_below_pct_for_label($label);
if ($suggested === null) {
    echo json_encode([
        "ok" => false,
        "error" => "No humidity stats for label: " . $label,
    ]);
    exit;
}

$c = ssws_crop_csv_cache();
$stats = isset($c["label_stats"][$label]) ? $c["label_stats"][$label] : null;

$out = [
    "ok" => true,
    "zone_key" => $zoneKey,
    "crop_label" => $label,
    "crop_display" => ucfirst($label),
    "humidity_water_below_pct" => (int) $suggested,
    "humidity_p25" => $stats ? round((float) $stats["p25"], 2) : null,
    "humidity_median" => $stats ? round((float) $stats["median"], 2) : null,
    "source" => $source,
];
if ($sim !== null) {
    $out["dataset_similarity"] = round($sim, 4);
}
echo json_encode($out);
