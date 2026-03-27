<?php
/**
 * Absolute filesystem path to the app root (directory containing index.php).
 */
function ssws_app_root(): string
{
    return dirname(__DIR__);
}

/**
 * URL path segment(s) for this app from the web server document root (no leading/trailing slash).
 * Examples: "" or "bare-minimum".
 *
 * Prefer the directory of SCRIPT_FILENAME relative to DOCUMENT_ROOT so URLs stay correct when
 * SCRIPT_NAME is wrong or the site is run from a subdirectory of htdocs.
 */
function ssws_base_path(): string
{
    $docRoot = $_SERVER["DOCUMENT_ROOT"] ?? "";
    $scriptFile = $_SERVER["SCRIPT_FILENAME"] ?? "";
    if ($docRoot !== "" && $scriptFile !== "") {
        $docReal = @realpath($docRoot);
        $dirReal = @realpath(dirname($scriptFile));
        if (
            $docReal !== false
            && $dirReal !== false
            && strlen($dirReal) >= strlen($docReal)
            && strncmp($dirReal, $docReal, strlen($docReal)) === 0
        ) {
            $rel = substr($dirReal, strlen($docReal));
            $rel = str_replace("\\", "/", $rel);
            return trim($rel, "/");
        }
    }

    $script = $_SERVER["SCRIPT_NAME"] ?? "/";
    $dir = dirname($script);
    $dir = str_replace("\\", "/", $dir);
    $dir = rtrim($dir, "/");
    return ltrim($dir, "/");
}

/**
 * Root-relative URL to a file under the app (always starts with /).
 */
function ssws_url(string $path): string
{
    $path = ltrim(str_replace("\\", "/", $path), "/");
    $base = ssws_base_path();
    return "/" . ($base !== "" ? $base . "/" : "") . $path;
}
