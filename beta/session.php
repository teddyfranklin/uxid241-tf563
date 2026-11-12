<?php
declare(strict_types=1);

// AI: generated with Claude Code. Include-only file: opening it directly in the browser gets a 404 instead of
// running half a page (and printing PHP errors that reveal server paths).
if (realpath($_SERVER['SCRIPT_FILENAME']) === __FILE__) {
  http_response_code(404);
  exit;
}
// session.php - starts the session with a hardened cookie.
// Required by every beta page (directly, or through guard.php) so they all
// share the same cookie settings.
// AI: generated with Claude based on the week 6 lecture snippets (carried over from Alpha).

// Lecture: "Harden the session cookie" - must run before session_start().
// 'secure' is only on over HTTPS; XAMPP serves plain http://localhost, where a
// secure cookie would never be sent back and login would never stick.
session_set_cookie_params([
  'httponly' => true,   // JavaScript can't read the cookie.
  'secure' => !empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off',
  'samesite' => 'Lax',  // The browser won't send the cookie on a POST from another site.
]);

// Lecture: "Starting a session"
session_start();
