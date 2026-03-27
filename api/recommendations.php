<?php
session_start();
header("Content-Type: application/json");

if (!isset($_SESSION["user"])) {
    http_response_code(401);
    echo json_encode(["error" => "Unauthorized"]);
    exit;
}

require_once dirname(__DIR__) . "/config.php";
require_once dirname(__DIR__) . "/includes/domain/recommendations_data.php";

$user = $_SESSION["user"];
echo json_encode(ssws_recommendations_payload($conn, $user));
