<?php
declare(strict_types=1);

// AI: generated with Claude Code. Include-only file: opening it directly in the browser gets a 404 instead of
// running half a page (and printing PHP errors that reveal server paths).
if (realpath($_SERVER['SCRIPT_FILENAME']) === __FILE__) {
  http_response_code(404);
  exit;
}
// header.php - the top of every beta page: <head>, site title and nav links.
// AI: generated with Claude Code (entire file).
//
// The page that includes this sets:
//   $page_title    text for the <title> tag
//   $root          path from the current page back to beta/ ('' or '../')
//   $current_user  ['id' => ..., 'email' => ...] when logged in, otherwise null
$current_user = $current_user ?? null;
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><?= htmlspecialchars($page_title) ?> - Recipe site beta</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="<?= $root ?>../assets/styles/main.css">
  <link rel="stylesheet" href="<?= $root ?>styles/beta.css">
</head>
<body>
  <h1 class="site-title"><a href="<?= $root ?>index.php">Recipe site beta</a></h1>

  <!-- Links change depending on whether someone is logged in. -->
  <nav class="auth-links">
    <a href="<?= $root ?>index.php">Recipes</a>
    <?php if ($current_user !== null): ?>
      <a href="<?= $root ?>admin/index.php">Admin</a>
      <span>Signed in as <?= htmlspecialchars($current_user['email']) ?></span>
      <a href="<?= $root ?>logout.php">Log out</a>
    <?php else: ?>
      <a href="<?= $root ?>login.php">Admin log in</a>
    <?php endif; ?>
  </nav>
