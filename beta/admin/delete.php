<?php
declare(strict_types=1);
// admin/delete.php - DELETE a recipe.
// AI: generated with Claude Code (entire file).
//
//   GET  delete.php?id=12   shows "Are you sure?" with a Delete button
//   POST delete.php         (id in a hidden field) actually deletes it
//
// Deleting only ever happens on POST, so following a link or reloading a page
// can't delete anything. The session cookie is SameSite=Lax (session.php), so
// the browser won't send it with a POST that comes from another website.

// Lecture: "Reuse the guard" - must be the first thing the page does.
require __DIR__ . '/../guard.php';
require __DIR__ . '/../functions.php';
$conn = require __DIR__ . '/../../assets/database/config.php';

$current_user = get_current_user_row($conn);
$root = '../';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $recipe_id = filter_var($_POST['id'] ?? '', FILTER_VALIDATE_INT);

  if ($recipe_id !== false && delete_recipe($conn, $recipe_id)) {
    header('Location: index.php?status=deleted');
    exit;
  }
  header('Location: index.php?status=not_found');
  exit;
}

// GET: look the recipe up so the confirmation can name it.
$recipe_id = filter_var($_GET['id'] ?? '', FILTER_VALIDATE_INT);
$recipe = $recipe_id === false ? null : get_recipe($conn, $recipe_id);

if ($recipe === null) {
  http_response_code(404);
}

$page_title = 'Delete recipe';
require __DIR__ . '/../partials/header.php';
?>

  <main class="admin-page">
    <?php if ($recipe === null): ?>
      <p class="admin-message">That recipe does not exist. <a href="index.php">Back to admin</a></p>
    <?php else: ?>
      <h2 class="admin-heading">Delete "<?= htmlspecialchars($recipe['title']) ?>"?</h2>
      <p class="admin-message">This also removes its ingredients, steps, tools and tips. It can't be undone.</p>

      <form class="delete-form" method="post" action="delete.php">
        <input type="hidden" name="id" value="<?= (int) $recipe['id'] ?>">
        <button type="submit" class="danger-button">Delete recipe</button>
        <a href="index.php">Cancel</a>
      </form>
    <?php endif; ?>
  </main>

<?php require __DIR__ . '/../partials/footer.php'; ?>
