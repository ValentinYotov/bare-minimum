<?php
require_once __DIR__ . "/zone_rules.php";
require_once __DIR__ . "/fire_log.php";

function ssws_run_automation(mysqli $conn, array $sensors, ?array $zoneRulesByKey = null): void
{
    $byKey = $zoneRulesByKey ?? [];

    foreach ($sensors as $s) {
        $sid = (int) $s["id"];
        $zk = $s["zone_key"] ?? "";
        $zoneRule = $byKey[$zk] ?? ssws_new_zone_rule_template();
        $humThreshold = (float) ($zoneRule["humidity_water_below_pct"] ?? 30.0);

        $location = $s["location"] ?? "Unknown";
        $status = $s["status"] ?? "normal";
        $hum = isset($s["humidity"]) ? (float) $s["humidity"] : 100.0;

        $state = ssws_automation_load_state($conn, $sid);
        $prevStatus = $state["prev_status"];
        $humidityOk = $state["humidity_ok"];

        if ($status === "fire" && $prevStatus !== "fire") {
            ssws_insert_fire_log(
                $conn,
                $sid,
                $location,
                "Sprinklers activated — wildfire / smoke detection",
                "wildfire"
            );
        }

        if ($hum < $humThreshold && $humidityOk) {
            ssws_insert_fire_log(
                $conn,
                $sid,
                $location,
                "Sprinklers activated — humidity below {$humThreshold}% (zone {$zk})",
                "humidity_low"
            );
            $humidityOk = false;
        }
        if ($hum >= $humThreshold) {
            $humidityOk = true;
        }

        ssws_automation_save_state($conn, $sid, $status, $humidityOk ? 1 : 0);
    }
}

function ssws_automation_load_state(mysqli $conn, int $sensorId): array
{
    $defaults = ["prev_status" => "normal", "humidity_ok" => 1];
    $stmt = $conn->prepare(
        "SELECT prev_status, humidity_ok FROM sensor_automation WHERE sensor_id = ? LIMIT 1"
    );
    if (!$stmt) {
        return $defaults;
    }
    $stmt->bind_param("i", $sensorId);
    $stmt->execute();
    $res = $stmt->get_result();
    $row = $res->fetch_assoc();
    $stmt->close();
    if (!$row) {
        return $defaults;
    }
    return [
        "prev_status" => $row["prev_status"] ?? "normal",
        "humidity_ok" => (int) ($row["humidity_ok"] ?? 1) === 1 ? 1 : 0,
    ];
}

function ssws_automation_save_state(
    mysqli $conn,
    int $sensorId,
    string $prevStatus,
    int $humidityOk
): void {
    $stmt = $conn->prepare(
        "INSERT INTO sensor_automation (sensor_id, prev_status, humidity_ok) VALUES (?, ?, ?)
         ON DUPLICATE KEY UPDATE prev_status = VALUES(prev_status), humidity_ok = VALUES(humidity_ok)"
    );
    if (!$stmt) {
        return;
    }
    $stmt->bind_param("isi", $sensorId, $prevStatus, $humidityOk);
    $stmt->execute();
    $stmt->close();
}
