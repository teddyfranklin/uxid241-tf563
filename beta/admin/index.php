<?php
declare(strict_types=1);
// admin/index.php - the admin dashboard: every recipe with Edit / Delete links.
// AI: generated with Claude Code (entire file).

// Lecture: "Reuse the guard" - must be the first thing the page does.
require __DIR__ . '/../guard.php';
require __DIR__ . '/../functions.php';
$conn = require __DIR__ . '/../../assets/database/config.php';

// Lecture: "Reading the current user" - the session only holds the id.
$current_user = get_current_user_row($conn);

// An empty search with category 0 means "every recipe".
$recipes = search_recipes($conn, '', 0);

// Messages after create / edit / delete. Only these fixed strings can ever be
// shown; whatever is in ?status= is just used to pick one of them.
$messages = [
  'created' => 'Recipe created.',
  'updated' => 'Recipe saved.',
  'deleted' => 'Recipe deleted.',
  'not_found' => 'That recipe no longer exists.',
];
$status = (string) ($_GET['status'] ?? '');
$message = $messages[$status] ?? '';

$page_title = 'Admin';
$root = '../';
require __DIR__ . '/../partials/header.php';
?>

  <main class="admin-page">
    <div class="admin-toolbar">
      <h2 class="admin-heading">Admin: <?= count($recipes) ?> recipes</h2>
      <a class="button-link" href="create.php">New recipe</a>
    </div>

    <?php if ($message !== ''): ?>
      <p class="admin-message" role="status"><?= htmlspecialchars($message) ?></p>
    <?php endif; ?>

    <table class="admin-table">
      <thead>
        <tr>
          <th scope="col">Title</th>
          <th scope="col">Category</th>
          <th scope="col">Servings</th>
          <th scope="col">Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php foreach ($recipes as $recipe): ?>
          <tr>
            <td><?= htmlspecialchars($recipe['title']) ?></td>
            <td><?= htmlspecialchars($recipe['category']) ?></td>
            <td><?= (int) $recipe['servings'] ?></td>
            <td class="admin-actions">
              <a href="../recipe.php?id=<?= (int) $recipe['id'] ?>">View</a>
              <a href="edit.php?id=<?= (int) $recipe['id'] ?>">Edit</a>
              <a href="delete.php?id=<?= (int) $recipe['id'] ?>">Delete</a>
            </td>
          </tr>
        <?php endforeach; ?>
      </tbody>
    </table>
  </main>

<?php require __DIR__ . '/../partials/footer.php'; ?>
