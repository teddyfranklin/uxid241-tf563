<?php

// generated with claude based on snippets
// Require it at the very top of every page in Alpha/admin/:
//   require __DIR__ . '/../guard.php';
declare(strict_types=1);
require __DIR__ . '/session.php';

// Lecture: "Protecting a page: the guard"
// '../login.php' resolves against the admin page's URL, so .. steps up to Alpha/.
if (!isset($_SESSION['user_id'])) {
  header('Location: ../login.php');
  exit; // without exit the protected page still renders
}
