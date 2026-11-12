<?php
declare(strict_types=1);
// recipe.php - READ: one recipe in full. Public. URL: recipe.php?id=12
// AI: generated with Claude Code (entire file).

require __DIR__ . '/session.php';
require __DIR__ . '/functions.php';
$conn = require __DIR__ . '/../assets/database/config.php';

$current_user = get_current_user_row($conn);
$root = '';

// FILTER_VALIDATE_INT gives false for anything that isn't a whole number.
$recipe_id = filter_var($_GET['id'] ?? '', FILTER_VALIDATE_INT);
$recipe = $recipe_id === false ? null : get_recipe($conn, $recipe_id);

if ($recipe === null) {
  http_response_code(404);
  $page_title = 'Recipe not found';
  require __DIR__ . '/partials/header.php';
  echo '<p class="admin-message recipe-detail">That recipe does not exist. <a href="index.php">Back to recipes</a></p>';
  require __DIR__ . '/partials/footer.php';
  exit;
}

$steps = get_recipe_steps($conn, $recipe_id);
$tips = get_recipe_tips($conn, $recipe_id);

$page_title = $recipe['title'];
require __DIR__ . '/partials/header.php';
?>

  <article class="recipe-detail">
    <p class="card-category"><?= htmlspecialchars($recipe['category']) ?></p>
    <h2><?= htmlspecialchars($recipe['title']) ?></h2>
    <?php if (!empty($recipe['subtitle'])): ?>
      <p class="recipe-subtitle"><?= htmlspecialchars($recipe['subtitle']) ?></p>
    <?php endif; ?>
    <p class="recipe-meta">Serves <?= (int) $recipe['servings'] ?></p>

    <?php if ($current_user !== null): ?>
      <p class="recipe-meta">
        <a href="admin/edit.php?id=<?= (int) $recipe['id'] ?>">Edit</a>
        &middot;
        <a href="admin/delete.php?id=<?= (int) $recipe['id'] ?>">Delete</a>
      </p>
    <?php endif; ?>

    <div class="recipe-image">
      <span>Image</span>
      <?php if (!empty($recipe['main_image'])): ?>
        <img src="../assets/<?= htmlspecialchars($recipe['main_image']) ?>"
             alt="<?= htmlspecialchars($recipe['title']) ?>"
             onerror="this.remove()">
      <?php endif; ?>
    </div>

    <h3>About</h3>
    <p><?= nl2br(htmlspecialchars($recipe['description'])) ?></p>

    <h3>Ingredients</h3>
    <ul>
      <?php foreach ($recipe['ingredients'] as $ingredient): ?>
        <li><?= htmlspecialchars($ingredient) ?></li>
      <?php endforeach; ?>
    </ul>

    <?php if (count($steps) > 0): ?>
      <h3>Steps</h3>
      <ol class="recipe-steps">
        <?php foreach ($steps as $step): ?>
          <li>
            <strong><?= htmlspecialchars($step['step_title']) ?></strong><br>
            <?= htmlspecialchars($step['step_instructions']) ?>
          </li>
        <?php endforeach; ?>
      </ol>
    <?php endif; ?>

    <?php if (count($tips) > 0): ?>
      <h3>Tips</h3>
      <?php foreach ($tips as $tip): ?>
        <p>
          <strong><?= htmlspecialchars((string) $tip['tip_title']) ?></strong><br>
          <?= htmlspecialchars((string) $tip['tip_text']) ?>
        </p>
      <?php endforeach; ?>
    <?php endif; ?>
  </article>

<?php require __DIR__ . '/partials/footer.php'; ?>
