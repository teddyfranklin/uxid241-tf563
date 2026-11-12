<?php
declare(strict_types=1);
// admin/create.php - CREATE: the "New recipe" form.
// AI: generated with Claude Code (entire file).

// Lecture: "Reuse the guard" - must be the first thing the page does.
require __DIR__ . '/../guard.php';
require __DIR__ . '/../functions.php';
$conn = require __DIR__ . '/../../assets/database/config.php';

$current_user = get_current_user_row($conn);
$categories = get_categories($conn);
$errors = [];

// Blank values for the first visit.
$recipe = [
  'title' => '',
  'subtitle' => '',
  'category_id' => '',
  'servings' => '',
  'description' => '',
  'main_image' => '',
  'ingredients' => [],
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  // Validate on the server first; nothing is written unless $errors is empty.
  [$recipe, $errors] = validate_recipe($_POST, $categories);

  if (count($errors) === 0) {
    try {
      $new_id = create_recipe($conn, $recipe);
      // Post/Redirect/Get: refreshing the next page won't submit the form twice.
      header('Location: index.php?status=created&id=' . $new_id);
      exit;
    } catch (mysqli_sql_exception $e) {
      $errors['form'] = 'The recipe could not be saved. Please try again.';
    }
  }
}

$page_title = 'New recipe';
$root = '../';
$form_action = 'create.php';
$submit_label = 'Create recipe';
require __DIR__ . '/../partials/header.php';
?>

  <main class="admin-page">
    <h2 class="admin-heading">New recipe</h2>
    <?php require __DIR__ . '/../partials/recipe_form.php'; ?>
  </main>

<?php require __DIR__ . '/../partials/footer.php'; ?>
