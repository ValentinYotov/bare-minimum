<?php
/**
 * Crop images: paths and optional Unsplash sources live in includes/data/crop_image_registry.json.
 * Runtime serves local files only (pre-downloaded). Optional "unsplash" per entry is for tools/download_crop_images_from_registry.php.
 */
require_once dirname(__DIR__) . "/ssws_paths.php";

/**
 * @return array<string, mixed>
 */
function ssws_crop_registry_load(): array
{
    static $cache = null;
    if ($cache !== null) {
        return $cache;
    }
    $path = dirname(__DIR__) . "/data/crop_image_registry.json";
    $raw = @file_get_contents($path);
    $decoded = json_decode((string) $raw, true);
    $cache = is_array($decoded) ? $decoded : [];
    return $cache;
}

function ssws_crop_normalize_display(string $s): string
{
    $s = mb_strtolower(trim($s), "UTF-8");
    $s = preg_replace("/\s+/u", " ", $s);
    return $s;
}

function ssws_crop_compact_key(string $s): string
{
    return preg_replace("/[\s\-_]+/u", "", $s);
}

/**
 * @return array{file: string, remote: bool}
 */
function ssws_crop_parse_image_entry(mixed $entry): array
{
    if (is_string($entry)) {
        $entry = trim($entry);
        if ($entry === "") {
            return ["file" => "", "remote" => false];
        }
        if (
            strpos($entry, "http://") === 0
            || strpos($entry, "https://") === 0
            || strpos($entry, "//") === 0
        ) {
            return ["file" => $entry, "remote" => true];
        }
        return ["file" => str_replace("\\", "/", $entry), "remote" => false];
    }
    if (!is_array($entry)) {
        return ["file" => "", "remote" => false];
    }
    $f = $entry["file"] ?? $entry["image_url"] ?? $entry["path"] ?? "";
    $f = is_string($f) ? trim($f) : "";
    if ($f === "") {
        return ["file" => "", "remote" => false];
    }
    if (
        strpos($f, "http://") === 0
        || strpos($f, "https://") === 0
        || strpos($f, "//") === 0
    ) {
        return ["file" => $f, "remote" => true];
    }
    return ["file" => str_replace("\\", "/", $f), "remote" => false];
}

/**
 * @param array<string, mixed> $rule
 * @return array{file: string, remote: bool}
 */
function ssws_crop_parse_rule_image(array $rule): array
{
    $f = $rule["file"] ?? $rule["image_url"] ?? "";
    return ssws_crop_parse_image_entry($f);
}

function ssws_crop_registry_fallback_path(array $reg): string
{
    $fb = (string) ($reg["fallback_image"] ?? $reg["default_image_url"] ?? "");
    return str_replace("\\", "/", trim($fb));
}

/**
 * @param array{file: string, remote: bool} $parsed
 */
function ssws_crop_resolve_parsed_to_url(array $parsed, array $reg): string
{
    $fallback = ssws_crop_registry_fallback_path($reg);
    if ($parsed["file"] === "") {
        return $fallback;
    }
    if ($parsed["remote"]) {
        return $parsed["file"];
    }
    $rel = ltrim($parsed["file"], "/");
    $root = ssws_app_root();
    $full = $root . "/" . $rel;
    if (is_file($full)) {
        return $rel;
    }
    return $fallback !== "" ? $fallback : $rel;
}

function ssws_crop_resolve_image_url(string $cropName): string
{
    $reg = ssws_crop_registry_load();
    $name = ssws_crop_normalize_display($cropName);
    if ($name === "") {
        return ssws_crop_registry_fallback_path($reg);
    }

    $labels = $reg["label_images"] ?? [];
    if (!is_array($labels)) {
        $labels = [];
    }

    $parsed = null;
    if (isset($labels[$name])) {
        $parsed = ssws_crop_parse_image_entry($labels[$name]);
    }
    $compact = ssws_crop_compact_key($name);
    if ($parsed === null && isset($labels[$compact])) {
        $parsed = ssws_crop_parse_image_entry($labels[$compact]);
    }

    if ($parsed === null) {
        $aliases = $reg["aliases"] ?? [];
        if (is_array($aliases)) {
            foreach ([$name, $compact] as $key) {
                if ($key === "" || !isset($aliases[$key])) {
                    continue;
                }
                $target = (string) $aliases[$key];
                if (isset($labels[$target])) {
                    $parsed = ssws_crop_parse_image_entry($labels[$target]);
                    break;
                }
                $tc = ssws_crop_compact_key($target);
                if (isset($labels[$tc])) {
                    $parsed = ssws_crop_parse_image_entry($labels[$tc]);
                    break;
                }
            }
        }
    }

    if ($parsed === null) {
        $rules = $reg["keyword_rules"] ?? [];
        if (!is_array($rules)) {
            $rules = [];
        }
        usort($rules, static function ($a, $b) {
            $la = strlen((string) ($a["match"] ?? ""));
            $lb = strlen((string) ($b["match"] ?? ""));
            return $lb <=> $la;
        });
        foreach ($rules as $rule) {
            if (!is_array($rule)) {
                continue;
            }
            $m = (string) ($rule["match"] ?? "");
            if ($m === "") {
                continue;
            }
            if (strpos($name, mb_strtolower($m, "UTF-8")) !== false) {
                $parsed = ssws_crop_parse_rule_image($rule);
                break;
            }
        }
    }

    if ($parsed === null) {
        $parsed = ["file" => "", "remote" => false];
    }

    return ssws_crop_resolve_parsed_to_url($parsed, $reg);
}
