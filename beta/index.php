<?php
declare(strict_types=1);
// index.php - the public recipe list with title search and the category filter.
// AI: generated with Claude Code, adapted from the Alpha index.php
// (moved onto the shared header/footer and functions.php, renamed to snake_case).

// Start the session so the nav can show whether someone is logged in.
// Must run before any HTML is printed.
require __DIR__ . '/session.php';
require __DIR__ . '/functions.php';
$conn = require __DIR__ . '/../assets/database/config.php';

$current_user = get_current_user_row($conn);
$categories = get_categories($conn);

// Remember what the user typed/picked so the form still shows it after a refresh.
// The same values are read by search.php for the live updates.
$search_text = trim((string) ($_GET['q'] ?? ''));
$selected_category = (int) ($_GET['category'] ?? 0);

$recipes = search_recipes($conn, $search_text, $selected_category);

$page_title = 'Recipes';
$root = '';
require __DIR__ . '/partials/header.php';
?>

  <!--
    One form holds the search bar AND the category buttons, so both are sent
    together. method="get" puts them in the URL (?q=...&category=...). Without
    JavaScript, pressing Enter reloads index.php with those values; with it,
    search.js fetches search.php (data-search-url) and swaps the cards in.
  -->
  <form id="search-form" class="layout" method="get" action="index.php" data-search-url="search.php">

    <input class="search-bar" type="search" name="q" placeholder="Title Search"
           aria-label="Search recipes by title"
           value="<?= htmlspecialchars($search_text) ?>">

    <!-- Radio buttons (not checkboxes): each recipe has only ONE category
         (recipe_info.category_id), so two at once would never match anything. -->
    <fieldset class="sidebar">
      <legend class="sidebar-heading">Category</legend>

      <!-- "All" has the value 0, which search_recipes() treats as "no filter". -->
      <label class="category-option">
        All
        <input type="radio" name="category" value="0" <?= $selected_category === 0 ? 'checked' : '' ?>>
      </label>

      <?php foreach ($categories as $category): ?>
        <label class="category-option">
          <?= htmlspecialchars($category['name']) ?>
          <input type="radio" name="category" value="<?= (int) $category['id'] ?>"
            <?= $selected_category === (int) $category['id'] ? 'checked' : '' ?>>
        </label>
      <?php endforeach; ?>
    </fieldset>

    <!-- aria-live tells screen readers to announce the new count after each search. -->
    <section id="results" class="results" aria-live="polite">
      <?php require __DIR__ . '/partials/results.php'; ?>
    </section>
  </form>

  <script src="scripts/search.js"></script>

<?php require __DIR__ . '/partials/footer.php'; ?>
