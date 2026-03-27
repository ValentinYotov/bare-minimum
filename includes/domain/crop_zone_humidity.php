<?php
/**
 * Crop profiles from Crop_recommendation.csv: nearest profile by N,P,K,ph,humidity (same 5 features as ai_services/recommendations/get_recommendations.py).
 * Suggested "water when humidity below" = lower-quartile humidity (p25) for that crop's rows, clamped to slider range.
 */
require_once __DIR__ . "/zone_rules.php";
require_once __DIR__ . "/sensors.php";

/** @var array{mins: float[], maxs: float[], rows: list<array{N:float,P:float,K:float,ph:float,humidity:float,label:string}>, label_stats: array<string, array{p25:float,median:float}>}|null */
function ssws_crop_csv_cache(): array
{
    static $cache = null;
    if ($cache !== null) {
        return $cache;
    }

    $path = dirname(__DIR__, 2) . "/ai_services/Crop_recommendation.csv";
    if (!is_readable($path)) {
        $cache = ["error" => "CSV not found"];
        return $cache;
    }

    $fh = fopen($path, "r");
    if (!$fh) {
        $cache = ["error" => "Cannot read CSV"];
        return $cache;
    }

    $header = fgetcsv($fh);
    if (!$header) {
        fclose($fh);
        $cache = ["error" => "Empty CSV"];
        return $cache;
    }

    $idx = [];
    foreach ($header as $i => $name) {
        $idx[trim($name)] = $i;
    }

    $need = ["N", "P", "K", "ph", "humidity", "label"];
    foreach ($need as $c) {
        if (!isset($idx[$c])) {
            fclose($fh);
            $cache = ["error" => "CSV missing column: " . $c];
            return $cache;
        }
    }

    $rows = [];
    $mins = [PHP_FLOAT_MAX, PHP_FLOAT_MAX, PHP_FLOAT_MAX, PHP_FLOAT_MAX, PHP_FLOAT_MAX];
    $maxs = [-PHP_FLOAT_MAX, -PHP_FLOAT_MAX, -PHP_FLOAT_MAX, -PHP_FLOAT_MAX, -PHP_FLOAT_MAX];

    while (($r = fgetcsv($fh)) !== false) {
        if (count($r) < max(array_values($idx)) + 1) {
            continue;
        }
        $N = (float) $r[$idx["N"]];
        $P = (float) $r[$idx["P"]];
        $K = (float) $r[$idx["K"]];
        $ph = (float) $r[$idx["ph"]];
        $hum = (float) $r[$idx["humidity"]];
        $label = strtolower(trim((string) $r[$idx["label"]]));
        if ($label === "") {
            continue;
        }

        $vec = [$N, $P, $K, $ph, $hum];
        for ($i = 0; $i < 5; $i++) {
            $mins[$i] = min($mins[$i], $vec[$i]);
            $maxs[$i] = max($maxs[$i], $vec[$i]);
        }
        $rows[] = ["N" => $N, "P" => $P, "K" => $K, "ph" => $ph, "humidity" => $hum, "label" => $label];
    }
    fclose($fh);

    $byLabel = [];
    foreach ($rows as $row) {
        $lb = $row["label"];
        if (!isset($byLabel[$lb])) {
            $byLabel[$lb] = [];
        }
        $byLabel[$lb][] = $row["humidity"];
    }

    $labelStats = [];
    foreach ($byLabel as $lb => $hums) {
        sort($hums, SORT_NUMERIC);
        $n = count($hums);
        if ($n === 0) {
            continue;
        }
        $mid = $n % 2 === 0
            ? ($hums[$n / 2 - 1] + $hums[$n / 2]) / 2.0
            : $hums[($n - 1) / 2];
        $p25 = ssws_percentile_sorted($hums, 0.25);
        $labelStats[$lb] = ["p25" => $p25, "median" => $mid];
    }

    $cache = [
        "mins" => $mins,
        "maxs" => $maxs,
        "rows" => $rows,
        "label_stats" => $labelStats,
    ];
    return $cache;
}

/**
 * @param list<float> $sorted
 */
function ssws_percentile_sorted(array $sorted, float $p): float
{
    $n = count($sorted);
    if ($n === 0) {
        return 0.0;
    }
    if ($n === 1) {
        return (float) $sorted[0];
    }
    $idx = $p * ($n - 1);
    $lo = (int) floor($idx);
    $hi = (int) ceil($idx);
    if ($lo === $hi) {
        return (float) $sorted[$lo];
    }
    return $sorted[$lo] + ($sorted[$hi] - $sorted[$lo]) * ($idx - $lo);
}

/**
 * @param float[] $vals length 5: N,P,K,ph,humidity
 * @param float[] $mins
 * @param float[] $maxs
 * @return float[]
 */
function ssws_normalize_feature_vector(array $vals, array $mins, array $maxs): array
{
    $out = [];
    for ($i = 0; $i < 5; $i++) {
        $out[] = ($vals[$i] - $mins[$i]) / ($maxs[$i] - $mins[$i] + 1e-8);
    }
    return $out;
}

/**
 * Cosine similarity (same space as Chroma cosine on normalized feature vectors).
 *
 * @param float[] $a
 * @param float[] $b
 */
function ssws_cosine_similarity(array $a, array $b): float
{
    $dot = 0.0;
    $na = 0.0;
    $nb = 0.0;
    for ($i = 0; $i < count($a); $i++) {
        $dot += $a[$i] * $b[$i];
        $na += $a[$i] * $a[$i];
        $nb += $b[$i] * $b[$i];
    }
    return $dot / (sqrt($na) * sqrt($nb) + 1e-8);
}

/**
 * @param array<string, mixed> $reading keys N,P,K,ph,humidity
 * @return array{best_label: string, similarity: float}|array{error: string}
 */
function ssws_nearest_dataset_crop_label(array $reading): array
{
    $c = ssws_crop_csv_cache();
    if (isset($c["error"])) {
        return ["error" => $c["error"]];
    }
    $mins = $c["mins"];
    $maxs = $c["maxs"];
    $rows = $c["rows"];

    $vals = [
        (float) ($reading["N"] ?? 0),
        (float) ($reading["P"] ?? 0),
        (float) ($reading["K"] ?? 0),
        (float) ($reading["ph"] ?? 0),
        (float) ($reading["humidity"] ?? 0),
    ];
    $q = ssws_normalize_feature_vector($vals, $mins, $maxs);

    $bestSim = -1.0;
    $bestLabel = "";
    foreach ($rows as $row) {
        $rv = [$row["N"], $row["P"], $row["K"], $row["ph"], $row["humidity"]];
        $e = ssws_normalize_feature_vector($rv, $mins, $maxs);
        $sim = ssws_cosine_similarity($q, $e);
        if ($sim > $bestSim) {
            $bestSim = $sim;
            $bestLabel = $row["label"];
        }
    }

    if ($bestLabel === "") {
        return ["error" => "No matching row"];
    }
    return ["best_label" => $bestLabel, "similarity" => $bestSim];
}

/**
 * Suggested humidity_water_below_pct for a dataset crop label (p25 of humidity in rows for that crop).
 */
function ssws_suggested_water_below_pct_for_label(string $label): ?float
{
    $c = ssws_crop_csv_cache();
    if (isset($c["error"])) {
        return null;
    }
    $key = strtolower(trim($label));
    $stats = $c["label_stats"][$key] ?? null;
    if (!$stats) {
        return null;
    }
    $p25 = (float) $stats["p25"];
    $pct = round(max(5.0, min(90.0, $p25)));
    return $pct;
}

/**
 * @return list<string> Sorted unique crop labels from the dataset (for dropdowns).
 */
function ssws_dataset_crop_labels_sorted(): array
{
    $c = ssws_crop_csv_cache();
    if (isset($c["error"])) {
        return [];
    }
    $keys = array_keys($c["label_stats"]);
    sort($keys, SORT_STRING);
    return $keys;
}

/**
 * Return normalized label if it exists in Crop_recommendation.csv, else "".
 */
function ssws_validate_planted_crop_label(string $raw): string
{
    $s = strtolower(trim($raw));
    if ($s === "") {
        return "";
    }
    $c = ssws_crop_csv_cache();
    if (isset($c["error"])) {
        return "";
    }
    return isset($c["label_stats"][$s]) ? $s : "";
}

/**
 * Guess crop from zone display name: longest dataset label found as substring (normalized text + compact form).
 */
function ssws_guess_crop_from_display_name(string $displayName): string
{
    $t = strtolower(trim($displayName));
    if ($t === "") {
        return "";
    }
    $norm = trim(preg_replace('/[^a-z0-9]+/', " ", $t));
    $norm = trim(preg_replace('/\s+/', " ", $norm));
    $compact = str_replace(" ", "", $norm);
    if ($norm === "" && $compact === "") {
        return "";
    }
    $c = ssws_crop_csv_cache();
    if (isset($c["error"])) {
        return "";
    }
    $labels = array_keys($c["label_stats"]);
    usort($labels, function ($a, $b) {
        return strlen($b) <=> strlen($a);
    });
    foreach ($labels as $lb) {
        if ($lb === "") {
            continue;
        }
        if ($norm !== "" && strpos($norm, $lb) !== false) {
            return $lb;
        }
        if ($compact !== "" && strpos($compact, $lb) !== false) {
            return $lb;
        }
    }
    return "";
}

/**
 * Sensor reading for a zone (same as recommendations / dashboard).
 *
 * @return array<string, float|int|string>
 */
function ssws_zone_reading_for_map_ai(mysqli $conn, string $username, string $zoneKey, string $zoneLabel): array
{
    $rules = ssws_load_all_zone_rules($conn, $username);
    $zoneRule = $rules[$zoneKey] ?? ssws_new_zone_rule_template();
    $sensor = ssws_mock_sensor_row($username, $zoneKey, $zoneRule);
    return [
        "zone_key" => $zoneKey,
        "zone_label" => $zoneLabel,
        "N" => (float) ($sensor["npk_n"] ?? 0),
        "P" => (float) ($sensor["npk_p"] ?? 0),
        "K" => (float) ($sensor["npk_k"] ?? 0),
        "ph" => (float) ($sensor["soil_ph"] ?? 0),
        "humidity" => (float) ($sensor["humidity"] ?? 0),
        "electrical_conductivity" => (float) ($sensor["soil_ec"] ?? 0),
    ];
}
