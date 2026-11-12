<?php
declare(strict_types=1);
// search.php - returns just the result cards for search.js to swap in.
// AI: generated with Claude Code, adapted from the Alpha assets/scripts/search.php.
//
// Reads the same two values as index.php:
//   ?q=chicken    text typed into the search bar (matched against the title)
//   &category=2   id of the selected category (0 or missing means "All")
// The query itself is in search_recipes() in functions.php (prepared statement + LIKE).

require __DIR__ . '/functions.php';
$conn = require __DIR__ . '/../assets/database/config.php';

$search_text = trim(input_string($_GET, 'q'));
$selected_category = (int) input_string($_GET, 'category'); // missing or non-numeric becomes 0 ("All")

$recipes = search_recipes($conn, $search_text, $selected_category);

require __DIR__ . '/partials/results.php';
