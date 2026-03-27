<?php

function ssws_zone_key_valid(string $k): bool
{
    return (bool) preg_match('/^[A-Za-z0-9_-]{1,36}$/', $k);
}

function ssws_new_zone_rule_template(): array
{
    return [
        "humidity_water_below_pct" => 30.0,
        "temp_normal_max_c" => 28.0,
        "temp_warning_max_c" => 35.0,
        "smoke_alert_pct" => 70.0,
        "display_name" => "",
        "subtitle" => "",
        "planted_crop" => "",
        "svg_x" => 8.0,
        "svg_y" => 8.0,
        "svg_w" => 180.0,
        "svg_h" => 120.0,
    ];
}

function ssws_sanitize_zone_string(?string $s, int $max = 128): string
{
    $s = trim((string) $s);
    if (strlen($s) > $max) {
        $s = substr($s, 0, $max);
    }
    return $s;
}

function ssws_clamp_zone_layout(array $rule): array
{
    $x = (float) ($rule["svg_x"] ?? 8);
    $y = (float) ($rule["svg_y"] ?? 8);
    $w = (float) ($rule["svg_w"] ?? 180);
    $h = (float) ($rule["svg_h"] ?? 120);

    $w = max(48.0, min(392.0, $w));
    $h = max(48.0, min(272.0, $h));
    $x = max(0.0, min(400.0 - $w, $x));
    $y = max(0.0, min(280.0 - $h, $y));

    $rule["svg_x"] = $x;
    $rule["svg_y"] = $y;
    $rule["svg_w"] = $w;
    $rule["svg_h"] = $h;
    return $rule;
}

function ssws_clamp_marker_in_zone(array $rule): array
{
    $rule = ssws_clamp_zone_layout($rule);
    $x = (float) $rule["svg_x"];
    $y = (float) $rule["svg_y"];
    $w = (float) $rule["svg_w"];
    $h = (float) $rule["svg_h"];
    $mr = 11.0;
    $defX = $x + $w / 2.0;
    $defY = $y + min($h * 0.28, 48.0);

    $mxRaw = $rule["marker_x"] ?? null;
    $myRaw = $rule["marker_y"] ?? null;
    $mx = ($mxRaw !== null && $mxRaw !== "" && is_numeric($mxRaw)) ? (float) $mxRaw : $defX;
    $my = ($myRaw !== null && $myRaw !== "" && is_numeric($myRaw)) ? (float) $myRaw : $defY;

    $mx = max($x + $mr, min($x + $w - $mr, $mx));
    $my = max($y + $mr, min($y + $h - $mr, $my));

    $rule["marker_x"] = $mx;
    $rule["marker_y"] = $my;
    return $rule;
}

/**
 * Detect layout columns: svg_x alone is enough (some DBs added layout without display_name).
 */
function ssws_zone_rules_has_layout_columns(mysqli $conn): bool
{
    $c1 = @$conn->query("SHOW COLUMNS FROM zone_rules LIKE 'svg_x'");
    $c2 = @$conn->query("SHOW COLUMNS FROM zone_rules LIKE 'display_name'");
    return ($c1 && $c1->num_rows > 0) || ($c2 && $c2->num_rows > 0);
}

function ssws_zone_rules_has_marker_columns(mysqli $conn): bool
{
    $c = @$conn->query("SHOW COLUMNS FROM zone_rules LIKE 'marker_x'");
    return $c && $c->num_rows > 0;
}

function ssws_zone_rules_has_sort_order(mysqli $conn): bool
{
    $c = @$conn->query("SHOW COLUMNS FROM zone_rules LIKE 'sort_order'");
    return $c && $c->num_rows > 0;
}

function ssws_zone_rules_has_planted_crop(mysqli $conn): bool
{
    $c = @$conn->query("SHOW COLUMNS FROM zone_rules LIKE 'planted_crop'");
    return $c && $c->num_rows > 0;
}

/** Last mysqli error from ssws_save_zone_rule (for API debugging). */
function ssws_zone_save_last_error(): string
{
    return (string) ($GLOBALS["ssws_zone_save_err"] ?? "");
}

/**
 * @return array{0: array<string, array>, 1: list<string>} [ zonesByKey, orderedKeys ]
 */
function ssws_load_all_zone_rules_ordered(mysqli $conn, string $username): array
{
    $out = [];
    $order = [];

    $chk = @$conn->query("SHOW TABLES LIKE 'zone_rules'");
    if (!$chk || $chk->num_rows === 0) {
        return [$out, $order];
    }

    $hasLayout = ssws_zone_rules_has_layout_columns($conn);
    $hasMarker = ssws_zone_rules_has_layout_columns($conn) && ssws_zone_rules_has_marker_columns($conn);
    $hasSort = ssws_zone_rules_has_sort_order($conn);
    $hasPlantedCrop = ssws_zone_rules_has_planted_crop($conn);
    $cropSel = $hasPlantedCrop ? ", planted_crop" : "";

    $orderSql = $hasSort ? "sort_order ASC, zone_key ASC" : "zone_key ASC";

    if ($hasMarker) {
        $sql = "SELECT zone_key, humidity_water_below_pct, temp_normal_max_c, temp_warning_max_c, smoke_alert_pct,
                       display_name, subtitle" . $cropSel . ", svg_x, svg_y, svg_w, svg_h, marker_x, marker_y
                FROM zone_rules WHERE username = ? ORDER BY " . $orderSql;
    } elseif ($hasLayout) {
        $sql = "SELECT zone_key, humidity_water_below_pct, temp_normal_max_c, temp_warning_max_c, smoke_alert_pct,
                       display_name, subtitle" . $cropSel . ", svg_x, svg_y, svg_w, svg_h
                FROM zone_rules WHERE username = ? ORDER BY " . $orderSql;
    } else {
        $sql = "SELECT zone_key, humidity_water_below_pct, temp_normal_max_c, temp_warning_max_c, smoke_alert_pct
                " . ($hasPlantedCrop ? ", planted_crop" : "") . "
                FROM zone_rules WHERE username = ? ORDER BY " . $orderSql;
    }

    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        return [$out, $order];
    }
    $stmt->bind_param("s", $username);
    $stmt->execute();
    $res = $stmt->get_result();
    while ($row = $res->fetch_assoc()) {
        $k = trim((string) ($row["zone_key"] ?? ""));
        if (!ssws_zone_key_valid($k)) {
            continue;
        }

        $base = ssws_new_zone_rule_template();
        $base["humidity_water_below_pct"] = (float) $row["humidity_water_below_pct"];
        $base["temp_normal_max_c"] = (float) $row["temp_normal_max_c"];
        $base["temp_warning_max_c"] = (float) $row["temp_warning_max_c"];
        $base["smoke_alert_pct"] = (float) $row["smoke_alert_pct"];

        if ($hasLayout) {
            $base["display_name"] = trim((string) ($row["display_name"] ?? ""));
            $base["subtitle"] = trim((string) ($row["subtitle"] ?? ""));
            $base["svg_x"] = (float) ($row["svg_x"] ?? $base["svg_x"]);
            $base["svg_y"] = (float) ($row["svg_y"] ?? $base["svg_y"]);
            $base["svg_w"] = (float) ($row["svg_w"] ?? $base["svg_w"]);
            $base["svg_h"] = (float) ($row["svg_h"] ?? $base["svg_h"]);
            $base = ssws_clamp_zone_layout($base);
            if ($hasMarker) {
                $mx = $row["marker_x"] ?? null;
                $my = $row["marker_y"] ?? null;
                if ($mx !== null && $mx !== "") {
                    $base["marker_x"] = (float) $mx;
                }
                if ($my !== null && $my !== "") {
                    $base["marker_y"] = (float) $my;
                }
            }
            $base = ssws_clamp_marker_in_zone($base);
        }

        if ($hasPlantedCrop && isset($row["planted_crop"])) {
            $base["planted_crop"] = trim((string) $row["planted_crop"]);
        }

        $out[$k] = $base;
        $order[] = $k;
    }
    $stmt->close();
    return [$out, $order];
}

/**
 * @return array<string, array>
 */
function ssws_load_all_zone_rules(mysqli $conn, string $username): array
{
    $pair = ssws_load_all_zone_rules_ordered($conn, $username);
    return $pair[0];
}

function ssws_next_sort_order(mysqli $conn, string $username): int
{
    if (!ssws_zone_rules_has_sort_order($conn)) {
        return 0;
    }
    $stmt = $conn->prepare("SELECT COALESCE(MAX(sort_order), 0) + 1 AS n FROM zone_rules WHERE username = ?");
    if (!$stmt) {
        return 0;
    }
    $stmt->bind_param("s", $username);
    $stmt->execute();
    $res = $stmt->get_result();
    $row = $res->fetch_assoc();
    $stmt->close();
    return (int) ($row["n"] ?? 1);
}

/**
 * Persist planted_crop after main INSERT (column added via sql/zone_rules_add_planted_crop.sql).
 */
function ssws_zone_rule_persist_planted_crop(mysqli $conn, string $username, string $zoneKey, array $rule): void
{
    if (!ssws_zone_rules_has_planted_crop($conn)) {
        return;
    }
    if (!array_key_exists("planted_crop", $rule)) {
        return;
    }
    require_once __DIR__ . "/crop_zone_humidity.php";
    $raw = trim((string) ($rule["planted_crop"] ?? ""));
    $pc = ssws_validate_planted_crop_label($raw);
    if ($pc === "") {
        $stmt = $conn->prepare("UPDATE zone_rules SET planted_crop = NULL WHERE username = ? AND zone_key = ?");
        if ($stmt) {
            $stmt->bind_param("ss", $username, $zoneKey);
            $stmt->execute();
            $stmt->close();
        }
        return;
    }
    $stmt = $conn->prepare("UPDATE zone_rules SET planted_crop = ? WHERE username = ? AND zone_key = ?");
    if (!$stmt) {
        return;
    }
    $stmt->bind_param("sss", $pc, $username, $zoneKey);
    $stmt->execute();
    $stmt->close();
}

function ssws_save_zone_rule(mysqli $conn, string $username, string $zoneKey, array $rule): bool
{
    $GLOBALS["ssws_zone_save_err"] = "";

    if (!ssws_zone_key_valid($zoneKey)) {
        $GLOBALS["ssws_zone_save_err"] = "Invalid zone key.";
        return false;
    }

    $h = (float) ($rule["humidity_water_below_pct"] ?? 30);
    $t1 = (float) ($rule["temp_normal_max_c"] ?? 28);
    $t2 = (float) ($rule["temp_warning_max_c"] ?? 35);
    $sm = (float) ($rule["smoke_alert_pct"] ?? 70);

    $h = max(5.0, min(95.0, $h));
    $t1 = max(0.0, min(55.0, $t1));
    $t2 = max(0.0, min(55.0, $t2));
    $sm = max(30.0, min(100.0, $sm));
    if ($t1 >= $t2) {
        $GLOBALS["ssws_zone_save_err"] = "temp_normal_max_c must be below temp_warning_max_c.";
        return false;
    }

    $defaults = ssws_new_zone_rule_template();
    $displayName = ssws_sanitize_zone_string($rule["display_name"] ?? $defaults["display_name"]);
    $subtitle = ssws_sanitize_zone_string($rule["subtitle"] ?? "");

    $rule["svg_x"] = $rule["svg_x"] ?? $defaults["svg_x"];
    $rule["svg_y"] = $rule["svg_y"] ?? $defaults["svg_y"];
    $rule["svg_w"] = $rule["svg_w"] ?? $defaults["svg_w"];
    $rule["svg_h"] = $rule["svg_h"] ?? $defaults["svg_h"];

    $chk = @$conn->query("SHOW TABLES LIKE 'zone_rules'");
    if (!$chk || $chk->num_rows === 0) {
        $GLOBALS["ssws_zone_save_err"] = "Table zone_rules does not exist.";
        return false;
    }

    $hasLayout = ssws_zone_rules_has_layout_columns($conn);
    $hasMarker = $hasLayout && ssws_zone_rules_has_marker_columns($conn);
    $hasSort = ssws_zone_rules_has_sort_order($conn);
    $sortNew = 0;

    if ($hasLayout && $hasMarker) {
        $rule = ssws_clamp_marker_in_zone($rule);
    } else {
        $rule = ssws_clamp_zone_layout($rule);
    }

    $sx = (float) $rule["svg_x"];
    $sy = (float) $rule["svg_y"];
    $sw = (float) $rule["svg_w"];
    $sh = (float) $rule["svg_h"];
    $mx = (float) ($rule["marker_x"] ?? 0);
    $my = (float) ($rule["marker_y"] ?? 0);

    if ($hasLayout && $hasMarker) {
        if ($hasSort) {
            $stmt = $conn->prepare(
                "INSERT INTO zone_rules (username, zone_key, sort_order, display_name, subtitle, svg_x, svg_y, svg_w, svg_h,
                 marker_x, marker_y, humidity_water_below_pct, temp_normal_max_c, temp_warning_max_c, smoke_alert_pct)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                 ON DUPLICATE KEY UPDATE
                 display_name = VALUES(display_name),
                 subtitle = VALUES(subtitle),
                 svg_x = VALUES(svg_x),
                 svg_y = VALUES(svg_y),
                 svg_w = VALUES(svg_w),
                 svg_h = VALUES(svg_h),
                 marker_x = VALUES(marker_x),
                 marker_y = VALUES(marker_y),
                 humidity_water_below_pct = VALUES(humidity_water_below_pct),
                 temp_normal_max_c = VALUES(temp_normal_max_c),
                 temp_warning_max_c = VALUES(temp_warning_max_c),
                 smoke_alert_pct = VALUES(smoke_alert_pct)"
            );
            if (!$stmt) {
                $GLOBALS["ssws_zone_save_err"] = $conn->error;
                return false;
            }
            $stmt->bind_param(
                "ssissdddddddddd",
                $username,
                $zoneKey,
                $sortNew,
                $displayName,
                $subtitle,
                $sx,
                $sy,
                $sw,
                $sh,
                $mx,
                $my,
                $h,
                $t1,
                $t2,
                $sm
            );
        } else {
            $stmt = $conn->prepare(
                "INSERT INTO zone_rules (username, zone_key, display_name, subtitle, svg_x, svg_y, svg_w, svg_h,
                 marker_x, marker_y, humidity_water_below_pct, temp_normal_max_c, temp_warning_max_c, smoke_alert_pct)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                 ON DUPLICATE KEY UPDATE
                 display_name = VALUES(display_name),
                 subtitle = VALUES(subtitle),
                 svg_x = VALUES(svg_x),
                 svg_y = VALUES(svg_y),
                 svg_w = VALUES(svg_w),
                 svg_h = VALUES(svg_h),
                 marker_x = VALUES(marker_x),
                 marker_y = VALUES(marker_y),
                 humidity_water_below_pct = VALUES(humidity_water_below_pct),
                 temp_normal_max_c = VALUES(temp_normal_max_c),
                 temp_warning_max_c = VALUES(temp_warning_max_c),
                 smoke_alert_pct = VALUES(smoke_alert_pct)"
            );
            if (!$stmt) {
                $GLOBALS["ssws_zone_save_err"] = $conn->error;
                return false;
            }
            $stmt->bind_param(
                "ssssdddddddddd",
                $username,
                $zoneKey,
                $displayName,
                $subtitle,
                $sx,
                $sy,
                $sw,
                $sh,
                $mx,
                $my,
                $h,
                $t1,
                $t2,
                $sm
            );
        }
        $ok = $stmt->execute();
        if (!$ok) {
            $GLOBALS["ssws_zone_save_err"] = $stmt->error !== "" ? $stmt->error : $conn->error;
        }
        $stmt->close();
        if ($ok) {
            ssws_zone_rule_persist_planted_crop($conn, $username, $zoneKey, $rule);
        }
        return $ok;
    }

    if ($hasLayout) {
        if ($hasSort) {
            $stmt = $conn->prepare(
                "INSERT INTO zone_rules (username, zone_key, sort_order, display_name, subtitle, svg_x, svg_y, svg_w, svg_h,
                 humidity_water_below_pct, temp_normal_max_c, temp_warning_max_c, smoke_alert_pct)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                 ON DUPLICATE KEY UPDATE
                 display_name = VALUES(display_name),
                 subtitle = VALUES(subtitle),
                 svg_x = VALUES(svg_x),
                 svg_y = VALUES(svg_y),
                 svg_w = VALUES(svg_w),
                 svg_h = VALUES(svg_h),
                 humidity_water_below_pct = VALUES(humidity_water_below_pct),
                 temp_normal_max_c = VALUES(temp_normal_max_c),
                 temp_warning_max_c = VALUES(temp_warning_max_c),
                 smoke_alert_pct = VALUES(smoke_alert_pct)"
            );
            if (!$stmt) {
                $GLOBALS["ssws_zone_save_err"] = $conn->error;
                return false;
            }
            $stmt->bind_param(
                "ssissdddddddd",
                $username,
                $zoneKey,
                $sortNew,
                $displayName,
                $subtitle,
                $sx,
                $sy,
                $sw,
                $sh,
                $h,
                $t1,
                $t2,
                $sm
            );
        } else {
            $stmt = $conn->prepare(
                "INSERT INTO zone_rules (username, zone_key, display_name, subtitle, svg_x, svg_y, svg_w, svg_h,
                 humidity_water_below_pct, temp_normal_max_c, temp_warning_max_c, smoke_alert_pct)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                 ON DUPLICATE KEY UPDATE
                 display_name = VALUES(display_name),
                 subtitle = VALUES(subtitle),
                 svg_x = VALUES(svg_x),
                 svg_y = VALUES(svg_y),
                 svg_w = VALUES(svg_w),
                 svg_h = VALUES(svg_h),
                 humidity_water_below_pct = VALUES(humidity_water_below_pct),
                 temp_normal_max_c = VALUES(temp_normal_max_c),
                 temp_warning_max_c = VALUES(temp_warning_max_c),
                 smoke_alert_pct = VALUES(smoke_alert_pct)"
            );
            if (!$stmt) {
                $GLOBALS["ssws_zone_save_err"] = $conn->error;
                return false;
            }
            $stmt->bind_param(
                "ssssdddddddd",
                $username,
                $zoneKey,
                $displayName,
                $subtitle,
                $sx,
                $sy,
                $sw,
                $sh,
                $h,
                $t1,
                $t2,
                $sm
            );
        }
        $ok = $stmt->execute();
        if (!$ok) {
            $GLOBALS["ssws_zone_save_err"] = $stmt->error !== "" ? $stmt->error : $conn->error;
        }
        $stmt->close();
        if ($ok) {
            ssws_zone_rule_persist_planted_crop($conn, $username, $zoneKey, $rule);
        }
        return $ok;
    }

    if ($hasSort) {
        $stmt = $conn->prepare(
            "INSERT INTO zone_rules (username, zone_key, sort_order, humidity_water_below_pct, temp_normal_max_c, temp_warning_max_c, smoke_alert_pct)
             VALUES (?, ?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
             humidity_water_below_pct = VALUES(humidity_water_below_pct),
             temp_normal_max_c = VALUES(temp_normal_max_c),
             temp_warning_max_c = VALUES(temp_warning_max_c),
             smoke_alert_pct = VALUES(smoke_alert_pct)"
        );
        if (!$stmt) {
            $GLOBALS["ssws_zone_save_err"] = $conn->error;
            return false;
        }
        $stmt->bind_param("ssidddd", $username, $zoneKey, $sortNew, $h, $t1, $t2, $sm);
    } else {
        $stmt = $conn->prepare(
            "INSERT INTO zone_rules (username, zone_key, humidity_water_below_pct, temp_normal_max_c, temp_warning_max_c, smoke_alert_pct)
             VALUES (?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
             humidity_water_below_pct = VALUES(humidity_water_below_pct),
             temp_normal_max_c = VALUES(temp_normal_max_c),
             temp_warning_max_c = VALUES(temp_warning_max_c),
             smoke_alert_pct = VALUES(smoke_alert_pct)"
        );
        if (!$stmt) {
            $GLOBALS["ssws_zone_save_err"] = $conn->error;
            return false;
        }
        $stmt->bind_param("ssdddd", $username, $zoneKey, $h, $t1, $t2, $sm);
    }
    $ok = $stmt->execute();
    if (!$ok) {
        $GLOBALS["ssws_zone_save_err"] = $stmt->error !== "" ? $stmt->error : $conn->error;
    }
    $stmt->close();
    if ($ok) {
        ssws_zone_rule_persist_planted_crop($conn, $username, $zoneKey, $rule);
    }
    return $ok;
}

function ssws_delete_zone_rule(mysqli $conn, string $username, string $zoneKey): bool
{
    if (!ssws_zone_key_valid($zoneKey)) {
        return false;
    }
    $stmt = $conn->prepare("DELETE FROM zone_rules WHERE username = ? AND zone_key = ? LIMIT 1");
    if (!$stmt) {
        return false;
    }
    $stmt->bind_param("ss", $username, $zoneKey);
    $ok = $stmt->execute() && $stmt->affected_rows > 0;
    $stmt->close();
    return $ok;
}

/**
 * Create a new zone with default layout; returns new zone_key or null.
 */
function ssws_create_zone(mysqli $conn, string $username): ?string
{
    $chk = @$conn->query("SHOW TABLES LIKE 'zone_rules'");
    if (!$chk || $chk->num_rows === 0) {
        return null;
    }

    if (!ssws_zone_rules_has_layout_columns($conn)) {
        return null;
    }

    $zoneKey = null;
    for ($attempt = 0; $attempt < 8; $attempt++) {
        $candidate = "z" . bin2hex(random_bytes(8));
        $check = $conn->prepare("SELECT 1 FROM zone_rules WHERE username = ? AND zone_key = ? LIMIT 1");
        if (!$check) {
            return null;
        }
        $check->bind_param("ss", $username, $candidate);
        $check->execute();
        $check->store_result();
        $taken = $check->num_rows > 0;
        $check->close();
        if (!$taken) {
            $zoneKey = $candidate;
            break;
        }
    }
    if ($zoneKey === null) {
        return null;
    }

    $rule = ssws_new_zone_rule_template();
    $rule["display_name"] = "New zone";
    $n = count(ssws_load_all_zone_rules($conn, $username));
    $rule["svg_x"] = 8.0 + (float) (($n % 4) * 24);
    $rule["svg_y"] = 8.0 + (float) ((int) ($n / 4) * 32);
    $rule = ssws_clamp_marker_in_zone($rule);

    $sort = ssws_zone_rules_has_sort_order($conn) ? ssws_next_sort_order($conn, $username) : 0;

    if (!ssws_save_zone_rule($conn, $username, $zoneKey, $rule)) {
        return null;
    }

    if (ssws_zone_rules_has_sort_order($conn)) {
        $stmt = $conn->prepare("UPDATE zone_rules SET sort_order = ? WHERE username = ? AND zone_key = ?");
        if ($stmt) {
            $stmt->bind_param("iss", $sort, $username, $zoneKey);
            $stmt->execute();
            $stmt->close();
        }
    }

    return $zoneKey;
}
