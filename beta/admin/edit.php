<?php
declare(strict_types=1);
// admin/edit.php - UPDATE: edit an existing recipe. URL: edit.php?id=12
// AI: generated with Claude Code (entire file).

// Lecture: "Reuse the guard" - must be the first thing the page does.
require __DIR__ . '/../guard.php';
require __DIR__ . '/../functions.php';
$conn = require __DIR__ . '/../../assets/database/config.php';

$current_user = get_current_user_row($conn);
$root = '../';

// The id always comes from the URL (the form posts back to edit.php?id=...).
// FILTER_VALIDATE_INT gives false for anything that isn't a whole number.
$recipe_id = filter_var($_GET['id'] ?? '', FILTER_VALIDATE_INT);
$existing = $recipe_id === false ? null : get_recipe($conn, $recipe_id);

if ($existing === null) {
  http_response_code(404);
  $page_title = 'Recipe not found';
  require __DIR__ . '/../partials/header.php';
  echo '<p class="admin-message">That recipe does not exist. <a href="index.php">Back to admin</a></p>';
  require __DIR__ . '/../partials/footer.php';
  exit;
}

$categories = get_categories($conn);
$errors = [];
$recipe = $existing; // first visit: fill the form from the database

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  [$recipe, $errors] = validate_recipe($_POST, $categories);

  if (count($errors) === 0) {
    try {
      update_recipe($conn, $recipe_id, $recipe);
      header('Location: index.php?status=updated&id=' . $recipe_id);
      exit;
    } catch (mysqli_sql_exception $e) {
      $errors['form'] = 'The recipe could not be saved. Please try again.';
    }
  }
}

$page_title = 'Edit ' . $existing['title'];
$form_action = 'edit.php?id=' . $recipe_id;
$submit_label = 'Save changes';
require __DIR__ . '/../partials/header.php';
?>

  <main class="admin-page">
    <h2 class="admin-heading">Edit "<?= htmlspecialchars($existing['title']) ?>"</h2>
    <?php require __DIR__ . '/../partials/recipe_form.php'; ?>
  </main>

<?php require __DIR__ . '/../partials/footer.php'; ?>
