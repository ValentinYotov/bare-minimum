<?php
require_once __DIR__ . "/includes/ssws_auth.php";
ssws_require_login();
require __DIR__ . "/config.php";

$username = $_SESSION["user"];
$message = "";
$message_ok = false;

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $alert_email = isset($_POST["alert_email"]) ? trim($_POST["alert_email"]) : "";
    $email_alerts = isset($_POST["email_alerts"]) ? 1 : 0;

    if ($alert_email !== "" && !filter_var($alert_email, FILTER_VALIDATE_EMAIL)) {
        $message = "Please enter a valid email address.";
    } else {
        $col = @$conn->query("SHOW COLUMNS FROM users LIKE 'alert_email'");
        if ($col && $col->num_rows > 0) {
            $stmt = $conn->prepare(
                "UPDATE users SET alert_email = ?, email_alerts = ? WHERE username = ?"
            );
            if ($stmt) {
                $ae = $alert_email === "" ? null : $alert_email;
                $stmt->bind_param("sis", $ae, $email_alerts, $username);
                if ($stmt->execute()) {
                    $message_ok = true;
                    $message = "Settings saved.";
                } else {
                    $message = "Could not save settings.";
                }
                $stmt->close();
            } else {
                $message = "Could not save settings.";
            }
        } else {
            $message =
                "Database columns missing. Run sql/schema_update.sql in phpMyAdmin, then try again.";
        }
    }
}

$alert_email_val = "";
$email_alerts_val = 1;
$col = @$conn->query("SHOW COLUMNS FROM users LIKE 'alert_email'");
if ($col && $col->num_rows > 0) {
    $stmt = $conn->prepare("SELECT alert_email, email_alerts FROM users WHERE username = ? LIMIT 1");
    $stmt->bind_param("s", $username);
    $stmt->execute();
    $r = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    if ($r) {
        $alert_email_val = $r["alert_email"] ?? "";
        $email_alerts_val = (int) ($r["email_alerts"] ?? 1);
    }
}

$alert_email_h = htmlspecialchars($alert_email_val, ENT_QUOTES, "UTF-8");

$ssws_active = "settings";
$ssws_title = "Settings";
require_once __DIR__ . "/includes/ssws_app_start.php";
?>

<div class="ssws-page-head">
    <h1>Settings</h1>
    <p>Alert notifications and emergency contact. Zone watering and thresholds are on the <a href="map.php">map</a>.</p>
</div>

<section class="ssws-card" style="max-width: 560px">
    <h2 class="ssws-settings-heading">Alert notifications</h2>
    <p class="ssws-settings-lead">
        When your hardware sends fire or irrigation events, use these preferences for future email or SMS hooks.
        Emergency phone is stored only in this browser.
    </p>
    <?php if ($message): ?>
        <p class="<?php echo $message_ok ? "ssws-msg-ok" : "ssws-msg-err"; ?>">
            <?php echo htmlspecialchars($message, ENT_QUOTES, "UTF-8"); ?>
        </p>
    <?php endif; ?>
    <form class="ssws-settings-form" method="post" id="settings-form" action="settings.php">
        <label for="alert_email">Alert email</label>
        <input type="email" id="alert_email" name="alert_email"
               value="<?php echo $alert_email_h; ?>"
               placeholder="you@example.com"
               autocomplete="email">

        <label class="checkbox-row">
            <input type="checkbox" name="email_alerts" value="1"
                <?php echo $email_alerts_val ? " checked" : ""; ?>>
            Send email alerts when fire or critical warnings are detected
        </label>

        <label for="emergency_phone">Emergency phone (browser only)</label>
        <input type="tel" id="emergency_phone" name="emergency_phone"
               placeholder="+359 … or local services"
               autocomplete="tel">
        <p class="ssws-settings-hint" id="emergency_phone_hint">
            Saved in this browser as you type. Use international format (e.g. +359…) for mobile.
            <strong>On a PC</strong>, “Call” opens an app on this computer (Phone Link, Skype, etc.) — it does not ring your phone unless that app is linked. <strong>On your phone’s browser</strong>, it opens the dialer.
        </p>
        <p class="ssws-settings-test-row">
            <button type="button" class="ssws-btn-secondary" id="emergency_phone_test">Test call link</button>
            <span class="ssws-settings-test-note" id="emergency_phone_test_msg" aria-live="polite"></span>
        </p>

        <button type="submit">Save settings</button>
    </form>
</section>

<script>
(function () {
  var key = "ssws_emergency_phone";
  var legacy = "agroguard_emergency_phone";
  var input = document.getElementById("emergency_phone");
  if (!input) return;
  var v = localStorage.getItem(key) || localStorage.getItem(legacy) || "";
  input.value = v;

  function persistPhone() {
    localStorage.setItem(key, (input.value || "").trim());
  }

  input.addEventListener("input", persistPhone);
  input.addEventListener("blur", persistPhone);

  var form = document.getElementById("settings-form");
  if (form) {
    form.addEventListener("submit", function () {
      persistPhone();
    });
  }

  var testBtn = document.getElementById("emergency_phone_test");
  var testMsg = document.getElementById("emergency_phone_test_msg");
  if (testBtn && testMsg) {
    testBtn.addEventListener("click", function () {
      persistPhone();
      var href =
        typeof window.sswsTelHref === "function"
          ? window.sswsTelHref(input.value)
          : "";
      if (!href || href === "tel:") {
        testMsg.textContent = "Enter a number first.";
        return;
      }
      testMsg.textContent =
        "Opening dialer for " + href + ". If nothing happens on a PC, read the note above.";
      window.location.href = href;
    });
  }
})();
</script>

<?php require_once __DIR__ . "/includes/ssws_app_end.php"; ?>
