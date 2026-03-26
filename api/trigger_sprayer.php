<?php
session_start();
header("Content-Type: application/json");
require dirname(__DIR__) . "/config.php";
require_once dirname(__DIR__) . "/includes/domain/sensors.php";
require_once dirname(__DIR__) . "/includes/domain/fire_log.php";

$sensorId = isset($_GET["sensor_id"]) ? (int) $_GET["sensor_id"] : 0;

if ($sensorId < 1) {
    http_response_code(400);
    echo json_encode(["error" => "Invalid sensor", "sensor_id" => $sensorId]);
    exit;
}

$user = $_SESSION["user"] ?? null;
if ($user === null || $user === "") {
    http_response_code(401);
    echo json_encode(["error" => "Unauthorized"]);
    exit;
}

$location = ssws_sensor_location_by_id($conn, $sensorId, $user);
$action = "Sprinklers activated — manual override";
$reason = "manual";

if (!ssws_insert_fire_log($conn, $sensorId, $location, $action, $reason)) {
    http_response_code(500);
    echo json_encode([
        "error" => "Could not log event. Check fire_logs table (see sql/schema_update.sql).",
    ]);
    exit;
}

echo json_encode([
    "sensor_id" => $sensorId,
    "message" => "Sprayer activated at " . $location . " (sensor " . $sensorId . ").",
]);
