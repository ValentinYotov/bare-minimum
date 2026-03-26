<?php
require_once __DIR__ . "/includes/ssws_auth.php";
ssws_require_login();
$ssws_active = "recommendations";
$ssws_title = "Recommendations";
require_once __DIR__ . "/includes/ssws_app_start.php";
?>

<div class="ssws-page-head">
    <h1>Recommendations</h1>
    <p>AI crop suggestions from NPK and soil data.</p>
</div>

<section class="ssws-placeholder">
    <p style="font-size:1.1rem;margin:0;">No recommendations yet.</p>
</section>

<?php require_once __DIR__ . "/includes/ssws_app_end.php"; ?>
