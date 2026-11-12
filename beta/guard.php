<?php
declare(strict_types=1);
// guard.php - protects every page in beta/admin/.
// Require it as the very first thing an admin page does:
//   require __DIR__ . '/../guard.php';
// AI: generated with Claude based on the week 6 lecture snippets (carried over from Alpha).

require __DIR__ . '/session.php';

// Lecture: "Protecting a page: the guard"
// The session only ever holds the user id, so "logged in" means "user_id is set".
// '../login.php' resolves against the admin page's URL, so .. steps up to beta/.
if (!isset($_SESSION['user_id'])) {
  header('Location: ../login.php');
  exit; // without exit the rest of the protected page still runs and renders
}
