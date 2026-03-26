<?php
require_once __DIR__ . "/includes/ssws_auth.php";
ssws_require_login();
$ssws_active = "chat";
$ssws_title = "AI Chat";
require_once __DIR__ . "/includes/ssws_app_start.php";
?>

<div class="ssws-page-head">
    <h1>AI Chat</h1>
    <p>Ask questions about your fields and irrigation (coming soon).</p>
</div>

<section class="ssws-placeholder">
    <h2>Coming soon</h2>
    <p>Your team can plug in an AI backend or chat API here — same layout as the mobile app.</p>
</section>

<?php require_once __DIR__ . "/includes/ssws_app_end.php"; ?>
