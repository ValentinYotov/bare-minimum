<?php
require_once __DIR__ . "/includes/ssws_auth.php";
ssws_require_login();
$ssws_active = "dashboard";
$ssws_title = "Dashboard";
require_once __DIR__ . "/includes/ssws_app_start.php";
?>

<div class="ssws-page-head">
    <h1>Dashboard</h1>
    <p>Monitor and control your irrigation system.</p>
</div>

<section class="ssws-summary" aria-label="Today summary">
    <dl class="ssws-summary__item">
        <dt>Water used</dt>
        <dd>245 L</dd>
    </dl>
    <dl class="ssws-summary__item">
        <dt>Last watered</dt>
        <dd>2h ago</dd>
    </dl>
    <dl class="ssws-summary__item">
        <dt>Fire status</dt>
        <dd><a href="alerts.php" style="color:inherit;font-weight:700;">No alerts</a></dd>
    </dl>
</section>

<div class="ssws-dash-grid">
    <section class="ssws-card" aria-labelledby="moisture-head">
        <div class="ssws-card__head" id="moisture-head">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></svg>
            Soil moisture
        </div>
        <p class="ssws-moisture-value">68%</p>
        <p class="ssws-moisture-trend">↑ +5% from yesterday</p>
        <div class="ssws-progress" role="progressbar" aria-valuenow="68" aria-valuemin="0" aria-valuemax="100">
            <div class="ssws-progress__fill"></div>
        </div>
        <p class="ssws-card__foot">Optimal moisture level</p>
    </section>

    <section class="ssws-card" aria-labelledby="water-head">
        <div class="ssws-card__head" id="water-head">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M12 8v8M8 12h8"/></svg>
            Watering system
        </div>
        <span class="ssws-badge-inactive" id="ssws-watering-badge">Inactive</span>
        <button type="button" class="ssws-btn-primary-lg" id="ssws-btn-start-watering">Start watering</button>
    </section>

    <section class="ssws-card" aria-labelledby="fire-head">
        <div class="ssws-card__head" id="fire-head">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="var(--ssws-green)" stroke-width="2"><path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.5-1-2-1-3.5a4.5 4.5 0 0 1 8 3c0 2.5-2.5 4.5-5 4.5-1.5 0-3-.5-4-1.5"/></svg>
            Fire detection
        </div>
        <div class="ssws-fire-ok">
            <div class="ssws-fire-ok__box" aria-hidden="true">✓</div>
            <strong>All clear</strong>
        </div>
        <p class="ssws-card__foot">No fire or smoke detected. System operating normally.</p>
        <p class="ssws-card__foot" style="margin-top:0.75rem;"><a href="alerts.php" style="color:var(--ssws-green);font-weight:600;">View alerts →</a></p>
    </section>
</div>

<section class="ssws-quick-actions" aria-labelledby="qa-head">
    <h2 id="qa-head">Quick actions</h2>
    <div class="ssws-quick-grid">
        <button type="button" class="ssws-quick-btn ssws-quick-btn--g" id="ssws-qa-schedule">Map &amp; zone rules</button>
        <button type="button" class="ssws-quick-btn ssws-quick-btn--b" id="ssws-qa-history">View history</button>
        <button type="button" class="ssws-quick-btn ssws-quick-btn--p" id="ssws-qa-calibrate">Sensor calibration</button>
        <button type="button" class="ssws-quick-btn ssws-quick-btn--o" id="ssws-qa-download">Download report</button>
    </div>
</section>

<script src="<?php echo htmlspecialchars(ssws_url("assets/js/dashboard.js"), ENT_QUOTES, "UTF-8"); ?>" defer></script>
<?php require_once __DIR__ . "/includes/ssws_app_end.php"; ?>
