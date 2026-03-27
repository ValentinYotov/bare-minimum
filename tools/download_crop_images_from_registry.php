<?php
/**
 * Reads includes/data/crop_image_registry.json and downloads each entry's "unsplash" URL
 * into the matching local "file" path. Use after pasting Unsplash image URLs from unsplash.com.
 *
 * Usage: php tools/download_crop_images_from_registry.php [--force]
 *   --force  Overwrite existing files
 */

declare(strict_types=1);

$root = dirname(__DIR__);
$jsonPath = $root . "/includes/data/crop_image_registry.json";
$force = in_array("--force", $argv ?? [], true);

$raw = file_get_contents($jsonPath);
if ($raw === false) {
    fwrite(STDERR, "Cannot read registry: {$jsonPath}\n");
    exit(1);
}

$data = json_decode($raw, true);
if (!is_array($data)) {
    fwrite(STDERR, "Invalid JSON\n");
    exit(1);
}

/**
 * @return list<array{file: string, unsplash: string}>
 */
function collect_download_pairs(array $data): array
{
    $out = [];
    $seen = [];

    $add = static function (mixed $entry) use (&$out, &$seen): void {
        if (!is_array($entry)) {
            return;
        }
        $file = isset($entry["file"]) && is_string($entry["file"]) ? trim($entry["file"]) : "";
        $url = isset($entry["unsplash"]) && is_string($entry["unsplash"]) ? trim($entry["unsplash"]) : "";
        if ($file === "" || $url === "") {
            return;
        }
        if (
            strpos($url, "http://") !== 0
            && strpos($url, "https://") !== 0
        ) {
            return;
        }
        if (strpos($file, "://") !== false) {
            return;
        }
        $key = $file . "\0" . $url;
        if (isset($seen[$key])) {
            return;
        }
        $seen[$key] = true;
        $out[] = ["file" => $file, "unsplash" => $url];
    };

    $labels = $data["label_images"] ?? [];
    if (is_array($labels)) {
        foreach ($labels as $entry) {
            $add(is_array($entry) ? $entry : []);
        }
    }

    $rules = $data["keyword_rules"] ?? [];
    if (is_array($rules)) {
        foreach ($rules as $rule) {
            $add(is_array($rule) ? $rule : []);
        }
    }

    return $out;
}

$pairs = collect_download_pairs($data);
$ctx = stream_context_create([
    "http" => [
        "header" => "User-Agent: Mozilla/5.0 (compatible; CropImageDownloader/1.0)\r\nAccept: image/*,*/*;q=0.8\r\n",
        "timeout" => 60,
        "follow_location" => 1,
    ],
    "https" => [
        "header" => "User-Agent: Mozilla/5.0 (compatible; CropImageDownloader/1.0)\r\nAccept: image/*,*/*;q=0.8\r\n",
        "timeout" => 60,
        "follow_location" => 1,
    ],
]);

$ok = 0;
$skip = 0;
$fail = 0;

foreach ($pairs as $pair) {
    $rel = str_replace("\\", "/", $pair["file"]);
    $rel = ltrim($rel, "/");
    $dest = $root . "/" . $rel;
    if (is_file($dest) && !$force) {
        fwrite(STDOUT, "skip (exists): {$rel}\n");
        $skip++;
        continue;
    }
    $dir = dirname($dest);
    if (!is_dir($dir)) {
        if (!@mkdir($dir, 0755, true) && !is_dir($dir)) {
            fwrite(STDERR, "mkdir failed: {$dir}\n");
            $fail++;
            continue;
        }
    }
    $bin = @file_get_contents($pair["unsplash"], false, $ctx);
    if ($bin === false || $bin === "") {
        fwrite(STDERR, "download failed: {$rel}\n");
        $fail++;
        continue;
    }
    if (strlen($bin) < 200) {
        fwrite(STDERR, "warning: tiny file {$rel} (" . strlen($bin) . " bytes) — check unsplash URL\n");
    }
    if (@file_put_contents($dest, $bin) === false) {
        fwrite(STDERR, "write failed: {$dest}\n");
        $fail++;
        continue;
    }
    fwrite(STDOUT, "OK {$rel}\n");
    $ok++;
}

fwrite(STDOUT, "\nDone. ok={$ok} skip={$skip} fail={$fail}\n");
exit($fail > 0 ? 2 : 0);
