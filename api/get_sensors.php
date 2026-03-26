<?php
session_start();
header("Content-Type: application/json");

if (!isset($_SESSION["user"])) {
    http_response_code(401);
    echo json_encode(["error" => "Unauthorized"]);
    exit;
}

require_once dirname(__DIR__) . "/config.php";
require_once dirname(__DIR__) . "/includes/domain/zone_rules.php";
require_once dirname(__DIR__) . "/includes/domain/sensors.php";
require_once dirname(__DIR__) . "/includes/domain/automation.php";

$user = $_SESSION["user"];
$zoneRules = ssws_load_all_zone_rules($conn, $user);
$sensors = ssws_sensors_snapshot($zoneRules, $user);

try {
    ssws_run_automation($conn, $sensors, $zoneRules);
} catch (Throwable $e) {
    error_log("[ssws] automation: " . $e->getMessage());
}

echo json_encode($sensors);
