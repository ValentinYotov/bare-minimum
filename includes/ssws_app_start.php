<?php
if (!isset($ssws_title)) {
    $ssws_title = "SSWS";
}
if (!isset($ssws_active)) {
    $ssws_active = "dashboard";
}
$page_title_safe = htmlspecialchars($ssws_title, ENT_QUOTES, "UTF-8");
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?php echo $page_title_safe; ?> — SSWS</title>
    <link rel="stylesheet" href="assets/css/ssws.css">
</head>
<body class="ssws-app">
    <div class="ssws-layout" id="ssws-layout">
        <?php include __DIR__ . "/ssws_sidebar.php"; ?>
        <div class="ssws-main-wrap">
            <?php include __DIR__ . "/ssws_app_header.php"; ?>
            <main class="ssws-main">
