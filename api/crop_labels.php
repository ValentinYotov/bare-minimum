<?php
session_start();
header("Content-Type: application/json");

if (!isset($_SESSION["user"])) {
    http_response_code(401);
    echo json_encode(["ok" => false, "error" => "Unauthorized"]);
    exit;
}

require_once dirname(__DIR__) . "/config.php";
require_once dirname(__DIR__) . "/includes/domain/crop_zone_humidity.php";

$labels = ssws_dataset_crop_labels_sorted();
echo json_encode([
    "ok" => true,
    "labels" => $labels,
]);
