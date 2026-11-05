<?php
declare(strict_types=1);
require __DIR__ . '/session.php';

// config.php creates the connection and returns it; the lecture calls it $conn.
$conn = require __DIR__ . '/../assets/database/config.php';

$error = '';
$email = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  // Lecture: "Login: look up by email, then verify"
  // Prepared statement, and the password is never part of the WHERE clause.
  $email = trim($_POST['email'] ?? '');
  $plain = $_POST['password'] ?? '';

  $result = mysqli_execute_query(
    $conn,
    'SELECT id, password_hash FROM users WHERE email = ?',
    [$email]
  );
  $user = mysqli_fetch_assoc($result);

  // Lecture: verify the password, then "Prevent session fixation"
  // password_verify() re-hashes $plain with the salt stored in the hash and
  // compares in constant time. session_regenerate_id(true) swaps to a new
  // session id and deletes the old one, so a planted id becomes worthless.
  if ($user !== null && password_verify($plain, $user['password_hash'])) {
    session_regenerate_id(true);

    // Store ONLY the user id.
    $_SESSION['user_id'] = $user['id'];

    header('Location: admin/index.php');
    exit;
  }

  // One vague message so nobody can tell which emails are registered.
  $error = 'Invalid email or password.';
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Log in - Recipe site alpha</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../assets/styles/main.css">
</head>
<body>
    <h1 class="site-title"><a href="index.php">Recipe site alpha</a></h1>

    <form class="auth-form" method="post">
        <h2>Log in</h2>

        <?php if ($error !== ''): ?>
            <p class="auth-error"><?= htmlspecialchars($error) ?></p>
        <?php endif; ?>

        <label>
            Email
            <input type="email" name="email" required value="<?= htmlspecialchars($email) ?>">
        </label>

        <label>
            Password
            <input type="password" name="password" required>
        </label>

        <button type="submit">Log in</button>

        <p>No account? <a href="register.php">Register</a></p>
    </form>
</body>
</html>
