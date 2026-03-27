<?php
require_once __DIR__ . "/includes/ssws_auth.php";
ssws_require_login();
$ssws_active = "map";
$ssws_title = "Map View";
require_once __DIR__ . "/includes/ssws_app_start.php";
?>

<div class="ssws-page-head ss-map-page-head">
    <h1>Map view</h1>
    <p>Drag <strong>zones</strong> to move them, use corner handles to resize, and drag the yellow <strong>sensor</strong> dots. Name zones and set thresholds in the panel — <strong>Save all zones</strong> writes every zone on the map to the database.</p>
</div>

<section class="ssws-weather ss-map-weather" aria-label="Current weather">
    <div>
        <p class="ssws-weather__temp">24°C</p>
        <p class="ss-map-weather-desc">Partly cloudy</p>
    </div>
    <div class="ssws-weather__meta" role="list">
        <span role="listitem">Humidity 65%</span>
        <span role="listitem">Wind 12 km/h</span>
        <span role="listitem">Rain 0%</span>
    </div>
</section>

<div class="ssws-map-layout ss-map-layout">
    <div class="ssws-field-map ss-map-field">
        <div class="ss-map-field-head">
            <h2 class="ss-map-field-title">Field layout</h2>
            <div class="ss-map-zone-toolbar">
                <button type="button" class="ss-map-toolbar-btn" id="ssws-zone-add">Add zone</button>
            </div>
        </div>
        <svg viewBox="0 0 400 280" xmlns="http://www.w3.org/2000/svg" id="ssws-field-svg" class="ss-map-svg" aria-label="Field zones">
            <defs>
                <linearGradient id="gradA" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" style="stop-color:#4ade80"/>
                    <stop offset="100%" style="stop-color:#16a34a"/>
                </linearGradient>
                <linearGradient id="gradB" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" style="stop-color:#67e8f9"/>
                    <stop offset="100%" style="stop-color:#0ea5e9"/>
                </linearGradient>
                <linearGradient id="gradC" x1="0%" y1="0%" x2="0%" y2="100%">
                    <stop offset="0%" style="stop-color:#a5b4fc"/>
                    <stop offset="100%" style="stop-color:#6366f1"/>
                </linearGradient>
            </defs>
            <g id="ssws-zones-layer"></g>
        </svg>
        <p class="ss-map-legend">
            <span class="ss-map-legend__dot" style="background:#fef08a"></span> Sensor (one per zone)
            <span class="ss-map-legend__hint">Drag to move or resize · tap zone or dot for quick focus</span>
        </p>
    </div>

    <div class="ssws-map-side ss-map-side">
        <div class="ssws-card ss-map-card ss-map-card--panel" id="ssws-zone-panel">
            <p class="ss-map-placeholder" id="ssws-zone-placeholder">Select a zone on the map to view live readings and adjust rules. Use “Add zone” if the map is empty.</p>

            <div id="ssws-zone-editor" class="ss-map-zone-editor" hidden>
                <div class="ss-map-zone-editor__head" id="ssws-zone-head">
                    <h3 id="ssws-zone-title" class="ss-map-zone-title">Zone A</h3>
                    <p id="ssws-zone-live" class="ss-map-zone-live"></p>
                </div>

                <p class="ss-map-zone-help">
                    <strong>Watering</strong> runs when <strong>humidity</strong> falls <em>below</em> the threshold (keeps plants from drying out).
                    <strong>Normal / warning / alert</strong> follow the temperature and smoke sliders below.
                </p>

                <div class="ss-map-zone-identity">
                    <label class="ss-map-label" for="zone-display-name">Zone name</label>
                    <input type="text" class="ss-map-text-input" id="zone-display-name" maxlength="128" placeholder="e.g. North orchard" autocomplete="off" />

                    <label class="ss-map-label" for="zone-planted-crop">Crop planted here</label>
                    <select class="ss-map-text-input" id="zone-planted-crop" aria-describedby="zone-planted-crop-hint">
                        <option value="">— Not set —</option>
                    </select>
                    <p class="ss-map-layout-hint" id="zone-planted-crop-hint">Optional. Used first for auto-setting the humidity threshold; we also try to match your zone name, then fall back to the nearest soil profile in the dataset.</p>

                    <p class="ss-map-layout-hint">Map uses a 400×280 grid. Drag zones and sensor dots; corner handles appear on the selected zone. Remove deletes this zone from your account.</p>

                    <button type="button" class="ss-map-remove-btn" id="ssws-zone-remove">Remove this zone</button>
                </div>

                <div class="ss-map-slider-block">
                    <label class="ss-map-label" for="zone-humidity">
                        Water when humidity below <span class="ss-map-val" id="zone-humidity-val">30</span>%
                    </label>
                    <p class="ss-map-ai-hint" id="zone-humidity-ai-hint" hidden></p>
                    <input type="range" class="ss-map-range" id="zone-humidity" min="5" max="90" step="1" value="30" />
                </div>

                <div class="ss-map-slider-block">
                    <label class="ss-map-label" for="zone-t1">
                        Upper limit of <strong>normal</strong> temp (°C): <span class="ss-map-val" id="zone-t1-val">28</span>
                    </label>
                    <input type="range" class="ss-map-range" id="zone-t1" min="10" max="45" step="0.5" value="28" />
                </div>

                <div class="ss-map-slider-block">
                    <label class="ss-map-label" for="zone-t2">
                        Upper limit of <strong>warning</strong> / start of alert (°C): <span class="ss-map-val" id="zone-t2-val">35</span>
                    </label>
                    <input type="range" class="ss-map-range" id="zone-t2" min="15" max="50" step="0.5" value="35" />
                </div>

                <div class="ss-map-slider-block">
                    <label class="ss-map-label" for="zone-smoke">
                        Smoke for <strong>alert</strong> (%): <span class="ss-map-val" id="zone-smoke-val">70</span>
                    </label>
                    <input type="range" class="ss-map-range" id="zone-smoke" min="30" max="100" step="1" value="70" />
                </div>

                <button type="button" class="ss-map-save-btn" id="ssws-zone-save">Save all zones</button>
                <p class="ss-map-save-msg" id="ssws-zone-msg" aria-live="polite"></p>
            </div>
        </div>
    </div>
</div>

<script src="<?php echo htmlspecialchars(ssws_url("assets/js/map.js"), ENT_QUOTES, "UTF-8"); ?>" defer></script>
<?php require_once __DIR__ . "/includes/ssws_app_end.php"; ?>
