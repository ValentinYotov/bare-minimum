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

$user = $_SESSION["user"];

function ssws_zone_rules_json_error(int $code, string $message, ?string $detail = null): void
{
    http_response_code($code);
    $out = ["error" => $message];
    if ($detail !== null && $detail !== "") {
        $out["detail"] = $detail;
    }
    echo json_encode($out);
}

if ($_SERVER["REQUEST_METHOD"] === "GET") {
    $pair = ssws_load_all_zone_rules_ordered($conn, $user);
    echo json_encode([
        "zones" => $pair[0],
        "zone_order" => $pair[1],
    ]);
    exit;
}

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    http_response_code(405);
    echo json_encode(["error" => "Method not allowed"]);
    exit;
}

$raw = file_get_contents("php://input");
$data = json_decode($raw, true);
if (!is_array($data)) {
    http_response_code(400);
    echo json_encode(["error" => "Invalid JSON"]);
    exit;
}

$action = isset($data["action"]) ? (string) $data["action"] : "save";

if ($action === "create") {
    $key = ssws_create_zone($conn, $user);
    if ($key === null) {
        ssws_zone_rules_json_error(
            500,
            "Could not create zone. Add layout columns (sql/schema_update.sql).",
            ssws_zone_save_last_error()
        );
        exit;
    }
    $pair = ssws_load_all_zone_rules_ordered($conn, $user);
    echo json_encode([
        "ok" => true,
        "zone_key" => $key,
        "zones" => $pair[0],
        "zone_order" => $pair[1],
    ]);
    exit;
}

if ($action === "delete") {
    $zone = isset($data["zone"]) ? (string) $data["zone"] : "";
    if (!ssws_zone_key_valid($zone)) {
        http_response_code(400);
        echo json_encode(["error" => "Invalid zone key"]);
        exit;
    }
    if (!ssws_delete_zone_rule($conn, $user, $zone)) {
        http_response_code(400);
        echo json_encode(["error" => "Zone not found or could not delete"]);
        exit;
    }
    $pair = ssws_load_all_zone_rules_ordered($conn, $user);
    echo json_encode([
        "ok" => true,
        "zones" => $pair[0],
        "zone_order" => $pair[1],
    ]);
    exit;
}

$zone = isset($data["zone"]) ? (string) $data["zone"] : "";
if (!ssws_zone_key_valid($zone)) {
    http_response_code(400);
    echo json_encode(["error" => "Invalid zone key"]);
    exit;
}

$rule = [
    "humidity_water_below_pct" => isset($data["humidity_water_below_pct"]) ? (float) $data["humidity_water_below_pct"] : 30.0,
    "temp_normal_max_c" => isset($data["temp_normal_max_c"]) ? (float) $data["temp_normal_max_c"] : 28.0,
    "temp_warning_max_c" => isset($data["temp_warning_max_c"]) ? (float) $data["temp_warning_max_c"] : 35.0,
    "smoke_alert_pct" => isset($data["smoke_alert_pct"]) ? (float) $data["smoke_alert_pct"] : 70.0,
    "display_name" => $data["display_name"] ?? null,
    "subtitle" => $data["subtitle"] ?? null,
    "svg_x" => isset($data["svg_x"]) ? (float) $data["svg_x"] : null,
    "svg_y" => isset($data["svg_y"]) ? (float) $data["svg_y"] : null,
    "svg_w" => isset($data["svg_w"]) ? (float) $data["svg_w"] : null,
    "svg_h" => isset($data["svg_h"]) ? (float) $data["svg_h"] : null,
    "marker_x" => array_key_exists("marker_x", $data) && $data["marker_x"] !== null ? (float) $data["marker_x"] : null,
    "marker_y" => array_key_exists("marker_y", $data) && $data["marker_y"] !== null ? (float) $data["marker_y"] : null,
];

if ($rule["temp_normal_max_c"] >= $rule["temp_warning_max_c"]) {
    http_response_code(400);
    echo json_encode(["error" => "Warning temperature must be above normal ceiling"]);
    exit;
}

if (!ssws_save_zone_rule($conn, $user, $zone, $rule)) {
    ssws_zone_rules_json_error(
        500,
        "Could not save. Check database migration (sql/schema_update.sql) and zone_key column size.",
        ssws_zone_save_last_error()
    );
    exit;
}

$pair = ssws_load_all_zone_rules_ordered($conn, $user);
echo json_encode([
    "ok" => true,
    "zones" => $pair[0],
    "zone_order" => $pair[1],
]);
