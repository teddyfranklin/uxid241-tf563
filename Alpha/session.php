<?php
// session.php - starts the session with a hardened cookie.
// Required by login.php, logout.php and guard.php so every page uses the same settings.
declare(strict_types=1);

// Lecture: "Harden the session cookie" - must run before session_start().
// 'secure' is only on over HTTPS; XAMPP serves plain http://localhost, where a
// secure cookie would never be sent back and login would never stick.
session_set_cookie_params([
  'httponly' => true,   // JavaScript can't read the cookie.
  'secure' => !empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off',
  'samesite' => 'Lax',  // Limits cross-site sending.
]);

// Lecture: "Starting a session"
session_start();
