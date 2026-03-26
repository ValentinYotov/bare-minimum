<?php
session_start();
header("Content-Type: application/json");

if (!isset($_SESSION["user"])) {
    http_response_code(401);
    echo json_encode(["error" => "Unauthorized"]);
    exit;
}

require dirname(__DIR__) . "/config.php";

$rows = [];
$res = @$conn->query(
    "SELECT sensor_id, action, location, trigger_reason, created_at AS `timestamp`
     FROM fire_logs ORDER BY created_at DESC LIMIT 200"
);

if ($res) {
    while ($row = $res->fetch_assoc()) {
        $rows[] = [
            "sensor_id" => (int) $row["sensor_id"],
            "action" => $row["action"],
            "location" => $row["location"],
            "trigger_reason" => $row["trigger_reason"],
            "timestamp" => $row["timestamp"],
        ];
    }
}

echo json_encode($rows);
