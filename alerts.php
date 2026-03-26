<?php
require_once __DIR__ . "/includes/ssws_auth.php";
ssws_require_login();
$ssws_active = "alerts";
$ssws_title = "Alerts";
require_once __DIR__ . "/includes/ssws_app_start.php";
?>

<div class="ssws-page-head">
    <h1>Active alerts</h1>
    <p>Review and resolve incidents across your fields.</p>
</div>

<section class="ssws-alert-stats" aria-label="Alert summary">
    <div class="ssws-stat-mini ssws-stat-mini--orange">
        <span aria-hidden="true">⚠</span>
        <div>
            <div class="ssws-stat-mini__num" id="ssws-stat-active">3</div>
            <div style="font-size:0.8rem;color:var(--ssws-muted);">Active</div>
        </div>
    </div>
    <div class="ssws-stat-mini ssws-stat-mini--red">
        <span aria-hidden="true">🔥</span>
        <div>
            <div class="ssws-stat-mini__num">1</div>
            <div style="font-size:0.8rem;color:var(--ssws-muted);">Critical</div>
        </div>
    </div>
    <div class="ssws-stat-mini ssws-stat-mini--orange">
        <span aria-hidden="true">💧</span>
        <div>
            <div class="ssws-stat-mini__num">1</div>
            <div style="font-size:0.8rem;color:var(--ssws-muted);">Warnings</div>
        </div>
    </div>
    <div class="ssws-stat-mini ssws-stat-mini--green">
        <span aria-hidden="true">✓</span>
        <div>
            <div class="ssws-stat-mini__num" id="ssws-stat-resolved">0</div>
            <div style="font-size:0.8rem;color:var(--ssws-muted);">Resolved (session)</div>
        </div>
    </div>
</section>

<div class="ssws-alert-feed" id="ssws-alert-feed">
    <article class="ssws-alert-item ssws-alert-item--critical" data-alert-id="fire-1">
        <div class="ssws-alert-item__top">
            <h3 style="color:var(--ssws-red);">Fire detected</h3>
            <span style="font-size:0.8rem;color:var(--ssws-muted);">2 hours ago</span>
        </div>
        <p>Smoke detector triggered in Zone A. Immediate attention required.</p>
        <p class="ssws-alert-item__loc">📍 Zone A — North Field</p>
        <div class="ssws-alert-actions">
            <button type="button" class="ssws-btn-outline js-alert-view" style="color:var(--ssws-red);border-color:var(--ssws-red);">View details</button>
            <button type="button" class="ssws-btn-outline js-alert-resolve" style="color:var(--ssws-muted);border-color:#cbd5e1;">Mark resolved</button>
        </div>
    </article>

    <article class="ssws-alert-item ssws-alert-item--warning" data-alert-id="moisture-1">
        <div class="ssws-alert-item__top">
            <h3 style="color:var(--ssws-orange);">Low soil moisture</h3>
            <span style="font-size:0.8rem;color:var(--ssws-muted);">4 hours ago</span>
        </div>
        <p>Soil moisture dropped to 45% in Zone B. Watering recommended.</p>
        <p class="ssws-alert-item__loc">📍 Zone B — Sensor B1</p>
        <div class="ssws-alert-actions">
            <button type="button" class="ssws-btn-outline js-alert-view" style="color:var(--ssws-orange);border-color:var(--ssws-orange);">View details</button>
            <button type="button" class="ssws-btn-outline js-alert-resolve" style="color:var(--ssws-muted);border-color:#cbd5e1;">Mark resolved</button>
        </div>
    </article>

    <article class="ssws-alert-item ssws-alert-item--info" data-alert-id="maint-1">
        <div class="ssws-alert-item__top">
            <h3 style="color:var(--ssws-blue);">Sensor maintenance due</h3>
            <span style="font-size:0.8rem;color:var(--ssws-muted);">1 day ago</span>
        </div>
        <p>Soil sensor A2 is due for a calibration check.</p>
        <p class="ssws-alert-item__loc">📍 Zone A — Sensor A2</p>
        <div class="ssws-alert-actions">
            <button type="button" class="ssws-btn-outline js-alert-view" style="color:var(--ssws-blue);border-color:var(--ssws-blue);">View details</button>
            <button type="button" class="ssws-btn-outline js-alert-resolve" style="color:var(--ssws-muted);border-color:#cbd5e1;">Mark resolved</button>
        </div>
    </article>
</div>

<script src="assets/js/alerts.js" defer></script>
<?php require_once __DIR__ . "/includes/ssws_app_end.php"; ?>
