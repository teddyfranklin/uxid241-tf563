<?php
declare(strict_types=1);

// Lecture: "Reuse the guard" - must be the first thing the page does.
require __DIR__ . '/../guard.php';

// config.php creates the connection and returns it; the lecture calls it $conn.
$conn = require __DIR__ . '/../../assets/database/config.php';

// Lecture: "Reading the current user" - the session only holds the id.
$result = mysqli_execute_query(
  $conn,
  'SELECT email FROM users WHERE id = ?',
  [$_SESSION['user_id']]
);
$user = mysqli_fetch_assoc($result);
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin - Recipe site alpha</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../../assets/styles/main.css">
</head>
<body>
    <h1 class="site-title"><a href="../index.php">Recipe site alpha</a></h1>

    <nav class="auth-links">
        <span>Signed in as <?= htmlspecialchars($user['email'] ?? '') ?></span>
        <a href="../logout.php">Log out</a>
    </nav>

    <h2 class="admin-heading">Admin</h2>
</body>
</html>
