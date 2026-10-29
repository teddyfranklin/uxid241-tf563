<?php
declare(strict_types=1);

// Connect to the database. require_once means search.php (included further down)
// won't connect a second time.
require_once __DIR__ . "/../assets/database/config.php";

// Gets every category so we can print one radio button per category.
function getCategories(mysqli $connection): array {
    $result = mysqli_query($connection, "SELECT id, name FROM categories ORDER BY name");
    return mysqli_fetch_all($result, MYSQLI_ASSOC);
}

$categories = getCategories($connection);

// Remember what the user typed/picked so the form still shows it after a page refresh.
$searchText = trim($_GET['q'] ?? '');
$selectedCategory = (int) ($_GET['category'] ?? 0);
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recipe site alpha</title>

    <!-- Inter, the font used in the Figma file -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400&display=swap" rel="stylesheet">

    <link rel="stylesheet" href="../assets/styles/main.css">
</head>
<body>
    <h1 class="site-title">Recipe site alpha</h1>

    <!--
        One form holds the search bar AND the category buttons, so both are
        sent together. method="get" puts them in the URL (?q=...&category=...),
        which is what search.php reads. data-search-url tells search.js where
        search.php lives.
    -->
    <form id="search-form" class="layout" method="get" data-search-url="../assets/scripts/search.php">

        <!-- Search bar -->
        <input class="search-bar" type="search" name="q" placeholder="Title Search"
               aria-label="Search recipes by title"
               value="<?= htmlspecialchars($searchText) ?>">

        <!-- Category sidebar.
             Radio buttons (not checkboxes): in the database each recipe has only
             ONE category (recipe_info.category_id), so picking two categories
             at once would never match anything. -->
        <fieldset class="sidebar">
            <legend class="sidebar-heading">Category</legend>

            <!-- "All" has the value 0, which search.php treats as "no filter". -->
            <label class="category-option">
                All
                <input type="radio" name="category" value="0" <?= $selectedCategory === 0 ? 'checked' : '' ?>>
            </label>

            <?php foreach ($categories as $category): ?>
                <label class="category-option">
                    <?= htmlspecialchars($category['name']) ?>
                    <input type="radio" name="category" value="<?= (int) $category['id'] ?>"
                        <?= $selectedCategory === (int) $category['id'] ? 'checked' : '' ?>>
                </label>
            <?php endforeach; ?>
        </fieldset>

        <!-- "X results" + the recipe cards.
             aria-live tells screen readers to announce the new count after each search. -->
        <section id="results" class="results" aria-live="polite">
            <?php
            // Print the cards for the first page load.
            // After that, search.js replaces everything in this box.
            include __DIR__ . "/../assets/scripts/search.php";
            ?>
        </section>
    </form>

    <script src="../assets/scripts/search.js"></script>
</body>
</html>
