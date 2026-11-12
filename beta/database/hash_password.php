<?php
declare(strict_types=1);
// hash_password.php - makes the password_hash() value for the seeded admin in beta.sql.
// AI: generated with Claude Code (entire file).
//
// Run it from a terminal, never through the browser:
//   php beta/database/hash_password.php          (XAMPP: C:\xampp\php\php.exe beta\database\hash_password.php)
// Type the password and press Enter. It prints a "$2y$..." hash; paste that into
// beta.sql in place of the old hash and re-import beta.sql.
//
// The plaintext only lives in $plain long enough to hash it. It is never saved,
// logged or printed (the terminal does show it while you type, like any prompt).

// Command line only: through the web server this file just returns 404.
if (PHP_SAPI !== 'cli') {
  http_response_code(404);
  exit;
}

fwrite(STDOUT, 'Password to hash: ');
$line = fgets(STDIN);
$plain = $line === false ? '' : rtrim($line, "\r\n");

if ($plain === '') {
  fwrite(STDERR, "No password entered.\n");
  exit(1);
}

// Lecture: "Hashing a password" - PASSWORD_DEFAULT is bcrypt today and adds its own random salt.
echo password_hash($plain, PASSWORD_DEFAULT), PHP_EOL;
