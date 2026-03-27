<?php
require_once __DIR__ . "/zone_rules.php";

function ssws_zone_sensor_id(string $username, string $zoneKey): int
{
    $h = crc32($username . "\0" . $zoneKey);
    return (int) (sprintf("%u", $h) % 900000) + 100000;
}

function ssws_mock_sensor_row(string $username, string $zoneKey, array $zoneRule): array
{
    $id = ssws_zone_sensor_id($username, $zoneKey);
    $seed = crc32($zoneKey) % 1000;
    $hum = 25 + ($seed % 55);
    $temp = 18 + ($seed % 28);
    $smoke = 25 + ($seed % 55);
    $npkN = 60 + ($seed % 80);
    $npkP = 28 + ($seed % 45);
    $npkK = 30 + ($seed % 50);
    $soilPh = round(5.5 + ($seed % 25) / 10, 2);
    $soilEc = round(0.25 + ($seed % 180) / 100, 2);
    $soilMoist = 40 + ($seed % 50);
    $display = trim((string) ($zoneRule["display_name"] ?? ""));
    $loc = $display !== "" ? $display : $zoneKey;

    return [
        "id" => $id,
        "zone_key" => $zoneKey,
        "zone" => $display !== "" ? $display : "Zone",
        "location" => $loc,
        "temperature" => $temp,
        "smoke" => $smoke,
        "humidity" => $hum,
        "npk_n" => $npkN,
        "npk_p" => $npkP,
        "npk_k" => $npkK,
        "soil_ph" => $soilPh,
        "soil_ec" => $soilEc,
        "soil_moisture_pct" => $soilMoist,
        "battery" => 40 + ($seed % 60),
        "signal" => $seed % 3 === 0 ? "Good" : ($seed % 3 === 1 ? "Fair" : "Weak"),
    ];
}

function ssws_compute_status(array $sensor, array $rules): string
{
    $temp = isset($sensor["temperature"]) ? (float) $sensor["temperature"] : 0.0;
    $smoke = isset($sensor["smoke"]) ? (float) $sensor["smoke"] : 0.0;

    $t1 = (float) ($rules["temp_normal_max_c"] ?? 28.0);
    $t2 = (float) ($rules["temp_warning_max_c"] ?? 35.0);
    $smokeAlert = (float) ($rules["smoke_alert_pct"] ?? 70.0);

    if ($smoke >= $smokeAlert) {
        return "fire";
    }
    if ($temp >= $t2) {
        return "fire";
    }
    if ($temp >= $t1) {
        return "warning";
    }
    return "normal";
}

function ssws_sensors_snapshot(?array $zoneRulesByKey, string $username): array
{
    $byKey = $zoneRulesByKey ?? [];
    $out = [];
    foreach ($byKey as $zk => $zoneRule) {
        $row = ssws_mock_sensor_row($username, $zk, $zoneRule);
        $row["status"] = ssws_compute_status($row, $zoneRule);
        $out[] = $row;
    }
    return $out;
}

function ssws_sensor_location_by_id(mysqli $conn, int $sensorId, string $username): string
{
    $rules = ssws_load_all_zone_rules($conn, $username);
    foreach (ssws_sensors_snapshot($rules, $username) as $s) {
        if ((int) $s["id"] === $sensorId) {
            return (string) ($s["location"] ?? "Unknown");
        }
    }
    return "Unknown location";
}
