<?php
declare(strict_types=1);

// AI: generated with Claude Code. Include-only file: opening it directly in the browser gets a 404 instead of
// running half a page (and printing PHP errors that reveal server paths).
if (realpath($_SERVER['SCRIPT_FILENAME']) === __FILE__) {
  http_response_code(404);
  exit;
}
// results.php - the "X results" line and one card per recipe.
// AI: generated with Claude Code, adapted from the Alpha search.php card markup.
//
// Used by index.php (first page load) and search.php (live updates from search.js).
// The page that includes this sets $recipes, the rows from search_recipes().
$count = count($recipes);
?>
<!-- "result" becomes "results" for anything other than 1. -->
<p class="result-count"><?= (int) $count ?> <?= $count === 1 ? 'result' : 'results' ?></p>

<div class="card-grid">
  <?php foreach ($recipes as $recipe): ?>
    <article class="card">
      <!-- Dark "Image" placeholder; the photo sits on top of it. Image paths look
           like "images/<recipe>/dish.jpg", so "../assets/" + path points into
           assets/images. If the file is missing, onerror removes the broken photo. -->
      <div class="card-image">
        <span>Image</span>
        <?php if (!empty($recipe['main_image'])): ?>
          <img src="../assets/<?= htmlspecialchars($recipe['main_image']) ?>"
               alt="<?= htmlspecialchars($recipe['title']) ?>"
               onerror="this.remove()">
        <?php endif; ?>
      </div>

      <div class="card-text">
        <p class="card-category"><?= htmlspecialchars($recipe['category']) ?></p>
        <h2 class="card-name">
          <a href="recipe.php?id=<?= (int) $recipe['id'] ?>"><?= htmlspecialchars($recipe['title']) ?></a>
        </h2>
        <p class="card-description"><?= htmlspecialchars($recipe['description']) ?></p>
      </div>
    </article>
  <?php endforeach; ?>
</div>
