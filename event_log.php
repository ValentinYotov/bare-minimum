<?php
require_once __DIR__ . "/includes/ssws_auth.php";
ssws_require_login();
require __DIR__ . "/config.php";

$rows = [];
$res = @$conn->query(
    "SELECT sensor_id, action, location, trigger_reason, created_at FROM fire_logs ORDER BY created_at DESC LIMIT 100"
);
if (!$res) {
    $res = @$conn->query(
        "SELECT sensor_id, action, created_at FROM fire_logs ORDER BY created_at DESC LIMIT 100"
    );
}
if ($res) {
    while ($row = $res->fetch_assoc()) {
        $rows[] = $row;
    }
}

$ssws_active = "dashboard";
$ssws_title = "Event log";
require_once __DIR__ . "/includes/ssws_app_start.php";
?>

<div class="ssws-page-head">
    <h1>Event log</h1>
    <p>Sprinkler activations and system events from the database.</p>
</div>

<section class="ssws-card">
    <?php if (!count($rows)): ?>
        <p style="margin:0;color:var(--ssws-muted);">No events yet. Use the dashboard or hardware hooks to create log entries.</p>
    <?php else: ?>
        <div style="overflow-x:auto;">
            <table style="width:100%;border-collapse:collapse;font-size:0.9rem;">
                <thead>
                    <tr style="text-align:left;border-bottom:2px solid #e2e8f0;">
                        <th style="padding:0.5rem;">Time</th>
                        <th style="padding:0.5rem;">Sensor</th>
                        <th style="padding:0.5rem;">Location</th>
                        <th style="padding:0.5rem;">Reason</th>
                        <th style="padding:0.5rem;">Action</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($rows as $r): ?>
                        <tr style="border-bottom:1px solid #e2e8f0;">
                            <td style="padding:0.5rem;"><?php echo htmlspecialchars($r["created_at"], ENT_QUOTES, "UTF-8"); ?></td>
                            <td style="padding:0.5rem;"><?php echo (int) $r["sensor_id"]; ?></td>
                            <td style="padding:0.5rem;"><?php echo htmlspecialchars(isset($r["location"]) ? $r["location"] : "—", ENT_QUOTES, "UTF-8"); ?></td>
                            <td style="padding:0.5rem;"><?php echo htmlspecialchars(isset($r["trigger_reason"]) ? $r["trigger_reason"] : "—", ENT_QUOTES, "UTF-8"); ?></td>
                            <td style="padding:0.5rem;"><?php echo htmlspecialchars($r["action"], ENT_QUOTES, "UTF-8"); ?></td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php endif; ?>
</section>

<?php require_once __DIR__ . "/includes/ssws_app_end.php"; ?>
