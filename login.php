<?php
session_start();
require __DIR__ . "/config.php";

if (isset($_SESSION["user"])) {
    header("Location: dashboard.php");
    exit;
}

$message = "";

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $username = $conn->real_escape_string($_POST["username"]);
    $password = $_POST["password"];

    $result = $conn->query("SELECT * FROM users WHERE username='$username'");
    if ($result->num_rows === 1) {
        $user = $result->fetch_assoc();
        if (password_verify($password, $user["password"])) {
            $_SESSION["user"] = $user["username"];
            header("Location: dashboard.php");
            exit;
        }
        $message = "Incorrect password.";
    } else {
        $message = "Username not found.";
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Log in — SSWS</title>
    <link rel="stylesheet" href="assets/css/ssws.css">
</head>
<body class="ssws-auth-page">
    <div class="ssws-auth-card">
        <h1>Welcome back</h1>
        <p class="ssws-auth-lead">Log in to your Smart Soil Watering System dashboard</p>
        <?php if ($message): ?>
            <p class="ssws-auth-msg"><?php echo htmlspecialchars($message, ENT_QUOTES, "UTF-8"); ?></p>
        <?php endif; ?>
        <form method="post" autocomplete="on">
            <label for="username">Username</label>
            <input type="text" id="username" name="username" placeholder="Your username" required>
            <label for="password">Password</label>
            <input type="password" id="password" name="password" placeholder="••••••••" required>
            <button type="submit">Log in</button>
        </form>
        <p class="ssws-auth-footer">No account? <a href="signup.php">Sign up</a></p>
        <p class="ssws-auth-footer"><a href="index.php">← Back to home</a></p>
    </div>
</body>
</html>
