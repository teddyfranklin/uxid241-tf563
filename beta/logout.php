<?php
declare(strict_types=1);
// logout.php - ends the admin session and goes back to the recipe list.
// AI: generated with Claude based on the week 6 lecture snippets (carried over from Alpha).
require __DIR__ . '/session.php';

// Lecture: "Logging out: destroy the session"
// 1. Clear the data for the rest of this request.
$_SESSION = [];

// Thorough logout: expire the session cookie too.
$params = session_get_cookie_params();
setcookie(session_name(), '', [
  'expires' => time() - 3600,
  'path' => $params['path'],
  'domain' => $params['domain'],
  'secure' => $params['secure'],
  'httponly' => $params['httponly'],
  'samesite' => $params['samesite'],
]);

// 2. Tell PHP to discard the server-side session.
session_destroy();

header('Location: index.php');
exit;
