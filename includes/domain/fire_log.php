<?php

function ssws_insert_fire_log(
    mysqli $conn,
    int $sensorId,
    string $location,
    string $action,
    string $triggerReason
): bool {
    $stmt = $conn->prepare(
        "INSERT INTO fire_logs (sensor_id, action, location, trigger_reason) VALUES (?, ?, ?, ?)"
    );
    if (!$stmt) {
        return false;
    }
    $stmt->bind_param("isss", $sensorId, $action, $location, $triggerReason);
    $ok = $stmt->execute();
    $stmt->close();
    return $ok;
}
