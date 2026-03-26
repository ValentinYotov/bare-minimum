<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
if (isset($_SESSION["user"])) {
    header("Location: dashboard.php");
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Smart Soil Watering System — SSWS</title>
    <link rel="stylesheet" href="assets/css/ssws.css">
</head>
<body class="ssws-landing">
    <section class="ssws-hero">
        <div class="ssws-hero__inner">
            <div>
                <h1 class="ssws-hero__title">Smart Soil Watering System</h1>
                <p class="ssws-hero__subtitle">Smart irrigation and safety for your crops</p>
                <p class="ssws-hero__desc">Monitor soil moisture, detect fire hazards, and get AI-powered crop recommendations — all in one intelligent system.</p>
                <div class="ssws-hero__actions">
                    <a class="ssws-btn-pill ssws-btn-pill--solid" href="login.php">Login</a>
                    <a class="ssws-btn-pill ssws-btn-pill--ghost" href="signup.php">Sign Up</a>
                </div>
            </div>
            <div class="ssws-hero__image-wrap">
                <img
                    src="https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=900&auto=format&fit=crop&q=80"
                    width="900"
                    height="675"
                    alt="Center-pivot irrigation in a green field under a clear sky"
                    loading="eager"
                >
            </div>
        </div>
    </section>

    <section class="ssws-landing-features" aria-labelledby="why-heading">
        <div class="ssws-landing-features__inner">
            <h2 id="why-heading">Why Choose SSWS?</h2>
            <p class="ssws-landing-features__sub">Harness the power of IoT and AI to optimize your agricultural operations</p>
            <div class="ssws-feature-grid">
                <article class="ssws-feature-card">
                    <div class="ssws-feature-card__icon ssws-feature-card__icon--green" aria-hidden="true">💧</div>
                    <h3>Smart Watering</h3>
                    <p>Automated irrigation based on real-time soil moisture levels. Save water and ensure optimal crop hydration.</p>
                </article>
                <article class="ssws-feature-card">
                    <div class="ssws-feature-card__icon ssws-feature-card__icon--orange" aria-hidden="true">🔥</div>
                    <h3>Fire Detection</h3>
                    <p>Real-time smoke and fire detection alerts to protect your crops and property from potential disasters.</p>
                </article>
                <article class="ssws-feature-card">
                    <div class="ssws-feature-card__icon ssws-feature-card__icon--blue" aria-hidden="true">✨</div>
                    <h3>AI Crop Recommendations</h3>
                    <p>Get personalized crop suggestions based on NPK sensors and soil conditions for maximum yield.</p>
                </article>
            </div>
        </div>
    </section>

    <footer class="ssws-landing-footer">
        <p>© <?php echo date("Y"); ?> SSWS · Smart Soil Watering System</p>
    </footer>

    <button type="button" class="ssws-fab" id="ssws-fab-help-landing" aria-label="Help">?</button>
    <script>
    document.getElementById("ssws-fab-help-landing")?.addEventListener("click", function () {
      alert("SSWS help — contact your team for support.");
    });
    </script>
</body>
</html>
