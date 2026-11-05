<?php
declare(strict_types=1);

// config.php creates the connection and returns it; the lecture calls it $conn.
$conn = require __DIR__ . '/../assets/database/config.php';

$error = '';
$email = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $email = trim($_POST['email'] ?? '');
  $plain = $_POST['password'] ?? '';

  if ($email === '' || $plain === '') {
    $error = 'Enter an email and a password.';
  } else {
    // Lecture: "Hashing a password" - only the hash is ever stored.
    $hash = password_hash($plain, PASSWORD_DEFAULT);

    // Lecture: "Registration: hash, then insert"
    // email is UNIQUE, so a duplicate signup throws and gets a friendly message.
    try {
      mysqli_execute_query(
        $conn,
        'INSERT INTO users (email, password_hash) VALUES (?, ?)',
        [$email, $hash]
      );

      header('Location: login.php');
      exit;
    } catch (mysqli_sql_exception $e) {
      // Duplicate email, or another insert failure.
      $error = 'That email is already registered.';
    }
  }
}

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register - Recipe site alpha</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../assets/styles/main.css">
</head>
<body>
    <h1 class="site-title"><a href="index.php">Recipe site alpha</a></h1>

    <form class="auth-form" method="post">
        <h2>Register</h2>

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

        <button type="submit">Register</button>

        <p>Already have an account? <a href="login.php">Log in</a></p>
    </form>
</body>
</html>
