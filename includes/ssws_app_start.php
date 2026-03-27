<?php
require_once __DIR__ . "/ssws_paths.php";

if (!isset($ssws_title)) {
    $ssws_title = "SSWS";
}
if (!isset($ssws_active)) {
    $ssws_active = "dashboard";
}
$page_title_safe = htmlspecialchars($ssws_title, ENT_QUOTES, "UTF-8");
$ssws_css_v = @filemtime(dirname(__DIR__) . "/assets/css/ssws.css") ?: 0;
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?php echo $page_title_safe; ?> — SSWS</title>
    <script>
    window.SSWS_BASE = <?php echo json_encode(ssws_base_path() === "" ? "" : "/" . ssws_base_path(), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
    window.sswsApi = function (path) {
      path = String(path || "").replace(/^\//, "");
      return window.SSWS_BASE ? window.SSWS_BASE + "/" + path : path;
    };
    </script>
    <link rel="stylesheet" href="<?php echo htmlspecialchars(ssws_url("assets/css/ssws.css") . "?v=" . (int) $ssws_css_v, ENT_QUOTES, "UTF-8"); ?>">
</head>
<body class="ssws-app">
    <div class="ssws-layout" id="ssws-layout">
        <?php include __DIR__ . "/ssws_sidebar.php"; ?>
        <div class="ssws-main-wrap">
            <?php include __DIR__ . "/ssws_app_header.php"; ?>
            <main class="ssws-main">
