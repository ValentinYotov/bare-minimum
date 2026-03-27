<?php
require_once __DIR__ . "/includes/ssws_auth.php";
ssws_require_login();
require_once __DIR__ . "/config.php";
require_once __DIR__ . "/includes/domain/recommendations_data.php";

$username = $_SESSION["user"];
$payload = ssws_recommendations_payload($conn, $username);
$reading = $payload["reading"];
$recs = $payload["recommendations"];
$isMock = !empty($payload["is_mock"]);
$dataSource = (string) ($payload["data_source"] ?? "");
$profilesUsed = (int) ($payload["retrieved_profiles_used"] ?? 0);
$notes = $payload["notes"];

function ssws_rec_h($s): string
{
    return htmlspecialchars((string) $s, ENT_QUOTES, "UTF-8");
}

function ssws_rec_conf_class(string $c): string
{
    $c = strtolower($c);
    if ($c === "high") {
        return "ssws-rec-badge ssws-rec-badge--high";
    }
    if ($c === "medium") {
        return "ssws-rec-badge ssws-rec-badge--medium";
    }
    return "ssws-rec-badge ssws-rec-badge--low";
}

function ssws_rec_format_source(string $ds): string
{
    switch ($ds) {
        case "dataset":
            return "Dataset";
        case "dataset+general_knowledge":
            return "Dataset + general knowledge";
        case "general_knowledge":
            return "General knowledge";
        default:
            return $ds;
    }
}

/** Visual fill 0–100 for the thin bar under each metric (illustrative vs agronomic ranges). */
function ssws_rec_metric_fill(string $metric, float $v): int
{
    switch ($metric) {
        case "N":
            return (int) min(100, max(0, round($v / 140 * 100)));
        case "P":
            return (int) min(100, max(0, round($v / 60 * 100)));
        case "K":
            return (int) min(100, max(0, round($v / 60 * 100)));
        case "ph":
            return (int) min(100, max(0, round($v / 14 * 100)));
        case "humidity":
            return (int) min(100, max(0, round($v)));
        case "ec":
            return (int) min(100, max(0, round($v / 2.5 * 100)));
        default:
            return 0;
    }
}

$zoneName = trim((string) ($reading["zone_label"] ?? ""));
if ($zoneName === "") {
    $zoneName = "—";
}

$ts = isset($reading["updated_at"]) ? strtotime((string) $reading["updated_at"]) : false;
$isoTime = $ts ? gmdate("c", $ts) : "";
$humanTime = $ts ? gmdate("M j, Y · H:i", $ts) . " UTC" : "";

$nVal = (float) ($reading["N"] ?? 0);
$pVal = (float) ($reading["P"] ?? 0);
$kVal = (float) ($reading["K"] ?? 0);
$phVal = (float) ($reading["ph"] ?? 0);
$humVal = (float) ($reading["humidity"] ?? 0);
$ecVal = (float) ($reading["electrical_conductivity"] ?? 0);

$ssws_active = "recommendations";
$ssws_title = "Recommendations";
require_once __DIR__ . "/includes/ssws_app_start.php";
?>

<div class="ssws-rec-page">
    <header class="ssws-rec-hero">
        <h1 class="ssws-rec-hero__title">Recommendations</h1>
        <p class="ssws-rec-hero__lead">Soil-driven crop ideas from NPK, pH, moisture &amp; EC — same fields as the AI service.</p>
    </header>

    <div class="ssws-rec-toolbar">
        <?php if ($isMock): ?>
            <span class="ssws-rec-pill ssws-rec-pill--mock">Sample data</span>
            <span class="ssws-rec-toolbar-note">Numbers below are placeholders until your sensor streams live readings.</span>
        <?php else: ?>
            <span class="ssws-rec-pill ssws-rec-pill--live">Live</span>
        <?php endif; ?>
    </div>

    <section class="ssws-rec-panel" aria-labelledby="rec-reading-head">
        <div class="ssws-rec-panel-head">
            <div class="ssws-rec-panel-icon" aria-hidden="true">
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75">
                    <path d="M12 22c-4.97 0-9-3.58-9-8 0-4.42 4.03-8 9-8s9 3.58 9 8c0 4.42-4.03 8-9 8z"/>
                    <path d="M12 6v12M8 10c1.5 2 2.5 4 4 6 1.5-2 2.5-4 4-6"/>
                </svg>
            </div>
            <div class="ssws-rec-panel-head-text">
                <h2 class="ssws-rec-panel-title" id="rec-reading-head">Soil snapshot</h2>
                <p class="ssws-rec-panel-lead">Latest reading used for matching against crop profiles.</p>
            </div>
        </div>

        <div class="ssws-rec-meta">
            <span class="ssws-rec-meta-kicker">Zone</span>
            <span class="ssws-rec-meta-name"><?php echo ssws_rec_h($zoneName); ?></span>
            <?php if ($isoTime !== ""): ?>
                <span class="ssws-rec-meta-sep" aria-hidden="true">·</span>
                <time class="ssws-rec-meta-time" datetime="<?php echo ssws_rec_h($isoTime); ?>">Updated <?php echo ssws_rec_h($humanTime); ?></time>
            <?php endif; ?>
        </div>

        <div class="ssws-rec-metrics">
            <div class="ssws-rec-metric ssws-rec-metric--n" style="--fill: <?php echo (int) ssws_rec_metric_fill("N", $nVal); ?>">
                <div class="ssws-rec-metric__bar" aria-hidden="true"></div>
                <span class="ssws-rec-metric__label">Nitrogen</span>
                <span class="ssws-rec-metric__value"><?php echo ssws_rec_h(number_format($nVal, 0)); ?></span>
                <span class="ssws-rec-metric__unit">kg/ha</span>
            </div>
            <div class="ssws-rec-metric ssws-rec-metric--p" style="--fill: <?php echo (int) ssws_rec_metric_fill("P", $pVal); ?>">
                <div class="ssws-rec-metric__bar" aria-hidden="true"></div>
                <span class="ssws-rec-metric__label">Phosphorus</span>
                <span class="ssws-rec-metric__value"><?php echo ssws_rec_h(number_format($pVal, 0)); ?></span>
                <span class="ssws-rec-metric__unit">kg/ha</span>
            </div>
            <div class="ssws-rec-metric ssws-rec-metric--k" style="--fill: <?php echo (int) ssws_rec_metric_fill("K", $kVal); ?>">
                <div class="ssws-rec-metric__bar" aria-hidden="true"></div>
                <span class="ssws-rec-metric__label">Potassium</span>
                <span class="ssws-rec-metric__value"><?php echo ssws_rec_h(number_format($kVal, 0)); ?></span>
                <span class="ssws-rec-metric__unit">kg/ha</span>
            </div>
            <div class="ssws-rec-metric ssws-rec-metric--ph" style="--fill: <?php echo (int) ssws_rec_metric_fill("ph", $phVal); ?>">
                <div class="ssws-rec-metric__bar" aria-hidden="true"></div>
                <span class="ssws-rec-metric__label">pH</span>
                <span class="ssws-rec-metric__value"><?php echo ssws_rec_h(number_format($phVal, 2)); ?></span>
                <span class="ssws-rec-metric__unit">scale 0–14</span>
            </div>
            <div class="ssws-rec-metric ssws-rec-metric--moist" style="--fill: <?php echo (int) ssws_rec_metric_fill("humidity", $humVal); ?>">
                <div class="ssws-rec-metric__bar" aria-hidden="true"></div>
                <span class="ssws-rec-metric__label">Moisture</span>
                <span class="ssws-rec-metric__value"><?php echo ssws_rec_h(number_format($humVal, 1)); ?></span>
                <span class="ssws-rec-metric__unit">%</span>
            </div>
            <div class="ssws-rec-metric ssws-rec-metric--ec" style="--fill: <?php echo (int) ssws_rec_metric_fill("ec", $ecVal); ?>">
                <div class="ssws-rec-metric__bar" aria-hidden="true"></div>
                <span class="ssws-rec-metric__label">EC</span>
                <span class="ssws-rec-metric__value"><?php echo ssws_rec_h(number_format($ecVal, 2)); ?></span>
                <span class="ssws-rec-metric__unit">mS/cm</span>
            </div>
        </div>
    </section>

    <section class="ssws-rec-results" aria-labelledby="rec-results-head">
        <div class="ssws-rec-results-head">
            <div>
                <h2 id="rec-results-head">Suggested crops</h2>
                <?php if ($dataSource !== "" && $dataSource !== "none"): ?>
                    <p class="ssws-rec-meta-line">
                        <?php echo ssws_rec_h(ssws_rec_format_source($dataSource)); ?>
                        <?php if ($profilesUsed > 0): ?>
                            · <?php echo (int) $profilesUsed; ?> similar soil profiles
                        <?php endif; ?>
                    </p>
                <?php endif; ?>
            </div>
        </div>

        <?php if ($notes): ?>
            <p class="ssws-rec-notes"><?php echo ssws_rec_h((string) $notes); ?></p>
        <?php endif; ?>

        <?php if (count($recs) === 0): ?>
            <div class="ssws-rec-empty ssws-card">
                <p>No recommendations yet. When live NPK data is wired in, results will show here.</p>
            </div>
        <?php else: ?>
            <div class="ssws-rec-list" role="list">
                <?php foreach ($recs as $row): ?>
                    <?php
                    $cropName = (string) ($row["crop"] ?? "");
                    $imgUrl = trim((string) ($row["image_url"] ?? ""));
                    if ($imgUrl === "") {
                        $imgUrl = ssws_recommendations_crop_image_url($cropName);
                    }
                    $imgAlt = $cropName !== "" ? $cropName . " — field reference photo" : "Crop reference photo";
                    ?>
                    <article class="ssws-rec-item" role="listitem">
                        <div class="ssws-rec-item-layout">
                            <figure class="ssws-rec-item-photo-wrap">
                                <img
                                    class="ssws-rec-item-photo"
                                    src="<?php echo ssws_rec_h($imgUrl); ?>"
                                    alt="<?php echo ssws_rec_h($imgAlt); ?>"
                                    width="480"
                                    height="360"
                                    loading="lazy"
                                    decoding="async"
                                />
                            </figure>
                            <div class="ssws-rec-item-copy">
                                <header class="ssws-rec-item-hd">
                                    <div class="ssws-rec-item-title">
                                        <h3 class="ssws-rec-crop"><?php echo ssws_rec_h($cropName); ?></h3>
                                    </div>
                                    <span class="<?php echo ssws_rec_conf_class((string) ($row["confidence"] ?? "")); ?>">
                                        <?php echo ssws_rec_h(ucfirst((string) ($row["confidence"] ?? ""))); ?> fit
                                    </span>
                                </header>
                                <p class="ssws-rec-reason"><?php echo ssws_rec_h($row["reasoning"] ?? ""); ?></p>
                            </div>
                        </div>
                    </article>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </section>
</div>

<?php require_once __DIR__ . "/includes/ssws_app_end.php"; ?>
