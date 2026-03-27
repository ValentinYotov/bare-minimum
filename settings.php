<?php
require_once __DIR__ . "/includes/ssws_auth.php";
ssws_require_login();
require __DIR__ . "/config.php";

$username = $_SESSION["user"];
$msg_alerts = "";
$msg_alerts_ok = false;
$msg_account = "";
$msg_account_ok = false;

$account_email = "";
$stmt = $conn->prepare("SELECT email FROM users WHERE username = ? LIMIT 1");
if ($stmt) {
    $stmt->bind_param("s", $username);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    if ($row) {
        $account_email = (string) ($row["email"] ?? "");
    }
}

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $section = isset($_POST["settings_section"]) ? (string) $_POST["settings_section"] : "alerts";

    if ($section === "password") {
        $current = isset($_POST["current_password"]) ? (string) $_POST["current_password"] : "";
        $new = isset($_POST["new_password"]) ? (string) $_POST["new_password"] : "";
        $confirm = isset($_POST["confirm_password"]) ? (string) $_POST["confirm_password"] : "";

        if ($current === "" || $new === "" || $confirm === "") {
            $msg_account = "Please fill in all password fields.";
        } elseif ($new !== $confirm) {
            $msg_account = "New password and confirmation do not match.";
        } elseif (strlen($new) < 8) {
            $msg_account = "New password must be at least 8 characters.";
        } else {
            $st = $conn->prepare("SELECT password FROM users WHERE username = ? LIMIT 1");
            if ($st) {
                $st->bind_param("s", $username);
                $st->execute();
                $ur = $st->get_result()->fetch_assoc();
                $st->close();
                if (!$ur || !password_verify($current, (string) ($ur["password"] ?? ""))) {
                    $msg_account = "Current password is incorrect.";
                } else {
                    $hash = password_hash($new, PASSWORD_BCRYPT);
                    $up = $conn->prepare("UPDATE users SET password = ? WHERE username = ?");
                    if ($up) {
                        $up->bind_param("ss", $hash, $username);
                        if ($up->execute()) {
                            $msg_account_ok = true;
                            $msg_account = "Password updated.";
                        } else {
                            $msg_account = "Could not update password.";
                        }
                        $up->close();
                    } else {
                        $msg_account = "Could not update password.";
                    }
                }
            } else {
                $msg_account = "Could not verify password.";
            }
        }
    } else {
        $alert_email = isset($_POST["alert_email"]) ? trim($_POST["alert_email"]) : "";
        $email_alerts = isset($_POST["email_alerts"]) ? 1 : 0;

        if ($alert_email !== "" && !filter_var($alert_email, FILTER_VALIDATE_EMAIL)) {
            $msg_alerts = "Please enter a valid email address.";
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
                        $msg_alerts_ok = true;
                        $msg_alerts = "Settings saved.";
                    } else {
                        $msg_alerts = "Could not save settings.";
                    }
                    $stmt->close();
                } else {
                    $msg_alerts = "Could not save settings.";
                }
            } else {
                $msg_alerts =
                    "Database columns missing. Run sql/schema_update.sql in phpMyAdmin, then try again.";
            }
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
$username_h = htmlspecialchars($username, ENT_QUOTES, "UTF-8");
$account_email_h = htmlspecialchars($account_email, ENT_QUOTES, "UTF-8");

$ssws_active = "settings";
$ssws_title = "Settings";
require_once __DIR__ . "/includes/ssws_app_start.php";
?>

<div class="ssws-page-head">
    <h1>Settings</h1>
    <p>Alert notifications and emergency contact. Zone watering and thresholds are on the <a href="<?php echo htmlspecialchars(ssws_url("map.php"), ENT_QUOTES, "UTF-8"); ?>">map</a>.</p>
</div>

<div class="ssws-settings-layout">
    <section class="ssws-card ssws-settings-card">
        <h2 class="ssws-settings-heading">Alert notifications</h2>
        <p class="ssws-settings-lead">
            When your hardware sends fire or irrigation events, use these preferences for future email or SMS hooks.
            Emergency phone is stored only in this browser.
        </p>
        <?php if ($msg_alerts): ?>
            <p class="<?php echo $msg_alerts_ok ? "ssws-msg-ok" : "ssws-msg-err"; ?>">
                <?php echo htmlspecialchars($msg_alerts, ENT_QUOTES, "UTF-8"); ?>
            </p>
        <?php endif; ?>
        <form class="ssws-settings-form" method="post" id="settings-form" action="settings.php">
            <input type="hidden" name="settings_section" value="alerts">
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

            <div class="ssws-settings-label-row">
                <label for="emergency_phone">Emergency phone (browser only)</label>
                <span class="ssws-tooltip-wrap">
                    <button type="button" class="ssws-info-btn" id="emergency_phone_info"
                            aria-label="How emergency calling works"
                            aria-describedby="emergency_phone_tooltip">?</button>
                    <span class="ssws-tooltip-bubble" id="emergency_phone_tooltip" role="tooltip">
                        <span class="ssws-tooltip-bubble__line">Saved in this browser as you type. Use international format (e.g. +359…) for mobile.</span>
                        <span class="ssws-tooltip-bubble__line"><strong>On a PC</strong>, “Call” opens an app on this computer (Phone Link, Skype, etc.) — it does not ring your phone unless that app is linked.</span>
                        <span class="ssws-tooltip-bubble__line"><strong>On your phone’s browser</strong>, it opens the dialer.</span>
                    </span>
                </span>
            </div>
            <input type="tel" id="emergency_phone" name="emergency_phone"
                   placeholder="+359 … or local services"
                   autocomplete="tel">
            <p class="ssws-settings-test-row">
                <button type="button" class="ssws-btn-secondary" id="emergency_phone_test">Test call link</button>
                <span class="ssws-settings-test-note" id="emergency_phone_test_msg" aria-live="polite"></span>
            </p>

            <button type="submit">Save settings</button>
        </form>
    </section>

    <section class="ssws-card ssws-settings-card">
        <h2 class="ssws-settings-heading">Account</h2>
        <p class="ssws-settings-lead">
            Your login identity and password for this app.
        </p>
        <?php if ($msg_account): ?>
            <p class="<?php echo $msg_account_ok ? "ssws-msg-ok" : "ssws-msg-err"; ?>">
                <?php echo htmlspecialchars($msg_account, ENT_QUOTES, "UTF-8"); ?>
            </p>
        <?php endif; ?>

        <div class="ssws-settings-account-summary">
            <div class="ssws-settings-account-row">
                <span class="ssws-settings-account-label">Username</span>
                <span class="ssws-settings-account-value"><?php echo $username_h; ?></span>
            </div>
            <div class="ssws-settings-account-row">
                <span class="ssws-settings-account-label">Email</span>
                <span class="ssws-settings-account-value"><?php echo $account_email !== "" ? $account_email_h : "—"; ?></span>
            </div>
        </div>

        <h3 class="ssws-settings-subheading">Change password</h3>
        <form class="ssws-settings-form" method="post" action="settings.php" autocomplete="off">
            <input type="hidden" name="settings_section" value="password">
            <label for="current_password">Current password</label>
            <input type="password" id="current_password" name="current_password"
                   autocomplete="current-password" required>

            <label for="new_password">New password</label>
            <input type="password" id="new_password" name="new_password"
                   minlength="8" autocomplete="new-password" required
                   placeholder="At least 8 characters">

            <label for="confirm_password">Confirm new password</label>
            <input type="password" id="confirm_password" name="confirm_password"
                   minlength="8" autocomplete="new-password" required>

            <button type="submit">Update password</button>
        </form>
    </section>
</div>

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
        "Opening dialer for " + href + ". If nothing happens on a PC, hover the ? next to the field.";
      window.location.href = href;
    });
  }
})();
</script>

<?php require_once __DIR__ . "/includes/ssws_app_end.php"; ?>
