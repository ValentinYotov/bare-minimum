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
    $email = $conn->real_escape_string($_POST["email"]);
    $password = password_hash($_POST["password"], PASSWORD_BCRYPT);

    $check = $conn->query("SELECT id FROM users WHERE username='$username' OR email='$email'");
    if ($check->num_rows > 0) {
        $message = "That username or email is already registered.";
    } else {
        $conn->query("INSERT INTO users (username,email,password) VALUES ('$username','$email','$password')");
        $_SESSION["user"] = $username;
        header("Location: dashboard.php");
        exit;
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Sign up — SSWS</title>
    <link rel="stylesheet" href="assets/css/ssws.css">
</head>
<body class="ssws-auth-page">
    <div class="ssws-auth-card">
        <h1>Create account</h1>
        <p class="ssws-auth-lead">Join SSWS — smart irrigation, fire safety, and AI insights for your farm.</p>
        <?php if ($message): ?>
            <p class="ssws-auth-msg"><?php echo htmlspecialchars($message, ENT_QUOTES, "UTF-8"); ?></p>
        <?php endif; ?>
        <form method="post" autocomplete="on">
            <label for="username">Username</label>
            <input type="text" id="username" name="username" placeholder="Choose a username" required>
            <label for="email">Email</label>
            <input type="email" id="email" name="email" placeholder="you@farm.example" required>
            <label for="password">Password</label>
            <input type="password" id="password" name="password" placeholder="••••••••" required>
            <button type="submit">Sign up</button>
        </form>
        <p class="ssws-auth-footer">Already registered? <a href="login.php">Log in</a></p>
        <p class="ssws-auth-footer"><a href="index.php">← Back to home</a></p>
    </div>
</body>
</html>
