<?php
declare(strict_types=1);

// AI: generated with Claude Code. Include-only file: opening it directly in the browser gets a 404 instead of
// running half a page (and printing PHP errors that reveal server paths).
if (realpath($_SERVER['SCRIPT_FILENAME']) === __FILE__) {
  http_response_code(404);
  exit;
}
// functions.php - every database query the beta pages use, in one place.
// AI: generated with Claude Code (entire file), following the week 4 CRUD and
// week 6/7 lecture patterns.
//
// Every query goes through mysqli_execute_query(). That one call does the three
// prepared-statement steps from the lecture: prepare the SQL with ? placeholders,
// bind the values in the array, and execute. User values never touch the SQL text.

// ---------- Reading form / URL input ----------

// Returns $source[$key] as a string, or '' if it's missing or not a string.
// A visitor can send ?q[]=x, which makes $_GET['q'] an ARRAY; with strict_types,
// passing that to trim() etc. would crash the page. This treats it as empty instead.
// Use it as input_string($_GET, 'q') or input_string($_POST, 'email').
function input_string(array $source, string $key): string {
  $value = $source[$key] ?? '';
  return is_string($value) ? $value : '';
}

// ---------- Users ----------

// The session only stores the user id, so look the email up when a page needs it.
function get_user_by_id(mysqli $conn, int $user_id): ?array {
  $result = mysqli_execute_query($conn, 'SELECT id, email FROM users WHERE id = ?', [$user_id]);
  return mysqli_fetch_assoc($result);
}

// Returns the logged-in user (or null) for pages that are public but show who is signed in.
function get_current_user_row(mysqli $conn): ?array {
  if (!isset($_SESSION['user_id'])) {
    return null;
  }
  return get_user_by_id($conn, (int) $_SESSION['user_id']);
}

// ---------- Categories ----------

function get_categories(mysqli $conn): array {
  $result = mysqli_execute_query($conn, 'SELECT id, name FROM categories ORDER BY name');
  return mysqli_fetch_all($result, MYSQLI_ASSOC);
}

// ---------- Reading recipes ----------

// Search (the graded beta feature) plus the category filter.
// Finds recipes whose title contains $search and, unless $category_id is 0 ("All"),
// that are in that category.
function search_recipes(mysqli $conn, string $search, int $category_id): array {
  $sql = 'SELECT r.id, t.title, t.subtitle, c.name AS category, i.servings,
                 i.description, i.main_image
          FROM recipes r
          JOIN recipe_titles t ON t.recipe_id = r.id
          JOIN recipe_info i ON i.recipe_id = r.id
          JOIN categories c ON c.id = i.category_id
          WHERE t.title LIKE ?
            AND (? = 0 OR i.category_id = ?)
          ORDER BY t.title';

  // In LIKE, % and _ are wildcards. Put a backslash in front of any the user
  // typed so "50%" searches for the text "50%", then wrap it in % so it matches
  // anywhere in the title. An empty search becomes '%%', which matches everything.
  $like = '%' . addcslashes($search, '%_\\') . '%';

  // The category id is bound twice: once for the "0 means All" check, once for the filter.
  $result = mysqli_execute_query($conn, $sql, [$like, $category_id, $category_id]);
  return mysqli_fetch_all($result, MYSQLI_ASSOC);
}

// One recipe with its ingredients, or null if the id doesn't exist.
function get_recipe(mysqli $conn, int $recipe_id): ?array {
  $result = mysqli_execute_query(
    $conn,
    'SELECT r.id, t.title, t.slug, t.subtitle, i.category_id, c.name AS category,
            i.servings, i.description, i.main_image
     FROM recipes r
     JOIN recipe_titles t ON t.recipe_id = r.id
     JOIN recipe_info i ON i.recipe_id = r.id
     JOIN categories c ON c.id = i.category_id
     WHERE r.id = ?',
    [$recipe_id]
  );
  $recipe = mysqli_fetch_assoc($result);
  if ($recipe === null) {
    return null;
  }

  $result = mysqli_execute_query(
    $conn,
    'SELECT ingredient FROM ingredients WHERE recipe_id = ? ORDER BY position',
    [$recipe_id]
  );
  // array_column turns [['ingredient' => 'x'], ...] into ['x', ...].
  $recipe['ingredients'] = array_column(mysqli_fetch_all($result, MYSQLI_ASSOC), 'ingredient');

  return $recipe;
}

function get_recipe_steps(mysqli $conn, int $recipe_id): array {
  $result = mysqli_execute_query(
    $conn,
    'SELECT step_number, step_title, step_instructions FROM steps WHERE recipe_id = ? ORDER BY step_number',
    [$recipe_id]
  );
  return mysqli_fetch_all($result, MYSQLI_ASSOC);
}

function get_recipe_tips(mysqli $conn, int $recipe_id): array {
  $result = mysqli_execute_query(
    $conn,
    'SELECT tip_title, tip_text FROM tips WHERE recipe_id = ? ORDER BY id',
    [$recipe_id]
  );
  return mysqli_fetch_all($result, MYSQLI_ASSOC);
}

// ---------- Validating the create / edit form ----------

// Checks the submitted form on the server (the browser's "required" can be skipped).
// Returns [$recipe, $errors]:
//   $recipe  the cleaned-up values, ready to save (also used to refill the form)
//   $errors  field name => message; empty means everything is valid
function validate_recipe(array $input, array $categories): array {
  $errors = [];

  $recipe = [
    'title' => trim(input_string($input, 'title')),
    'subtitle' => trim(input_string($input, 'subtitle')),
    'category_id' => input_string($input, 'category_id'),
    'servings' => trim(input_string($input, 'servings')),
    'description' => trim(input_string($input, 'description')),
    'main_image' => trim(input_string($input, 'main_image')),
    'ingredients' => [],
  ];

  // Title: required, fits the VARCHAR(255) column.
  if ($recipe['title'] === '') {
    $errors['title'] = 'Enter a title.';
  } elseif (mb_strlen($recipe['title']) > 255) {
    $errors['title'] = 'Keep the title under 255 characters.';
  }

  // Subtitle: optional.
  if (mb_strlen($recipe['subtitle']) > 255) {
    $errors['subtitle'] = 'Keep the subtitle under 255 characters.';
  }

  // Category: must be the id of a row that really exists in `categories`.
  $category_ids = array_map('intval', array_column($categories, 'id'));
  $category_id = filter_var($recipe['category_id'], FILTER_VALIDATE_INT);
  if ($category_id === false || !in_array($category_id, $category_ids, true)) {
    $errors['category_id'] = 'Pick a category.';
  } else {
    $recipe['category_id'] = $category_id;
  }

  // Servings: a whole number in a sensible range (the column is TINYINT UNSIGNED).
  $servings = filter_var($recipe['servings'], FILTER_VALIDATE_INT, [
    'options' => ['min_range' => 1, 'max_range' => 20],
  ]);
  if ($servings === false) {
    $errors['servings'] = 'Servings must be a whole number from 1 to 20.';
  } else {
    $recipe['servings'] = $servings;
  }

  // Description: required.
  if ($recipe['description'] === '') {
    $errors['description'] = 'Enter a description.';
  } elseif (mb_strlen($recipe['description']) > 5000) {
    $errors['description'] = 'Keep the description under 5000 characters.';
  }

  // Image path: optional. Same shape as the existing data ("images/<folder>/<file>"),
  // no ".." so it can't point outside assets/images.
  if ($recipe['main_image'] !== '') {
    if (mb_strlen($recipe['main_image']) > 255
        || !preg_match('#^images/[A-Za-z0-9._/-]+$#', $recipe['main_image'])
        || str_contains($recipe['main_image'], '..')) {
      $errors['main_image'] = 'Use a path like images/my-recipe/dish.jpg, or leave it blank.';
    }
  }

  // Ingredients: one per line. Blank lines are skipped. At least one is required.
  $lines = preg_split('/\R/', input_string($input, 'ingredients'));
  foreach ($lines as $line) {
    $line = trim($line);
    if ($line !== '') {
      $recipe['ingredients'][] = $line;
    }
  }
  if (count($recipe['ingredients']) === 0) {
    $errors['ingredients'] = 'Add at least one ingredient (one per line).';
  } elseif (count($recipe['ingredients']) > 50) {
    $errors['ingredients'] = 'Keep it to 50 ingredients or fewer.';
  } else {
    foreach ($recipe['ingredients'] as $ingredient) {
      if (mb_strlen($ingredient) > 255) {
        $errors['ingredients'] = 'Each ingredient line must be under 255 characters.';
        break;
      }
    }
  }

  return [$recipe, $errors];
}

// ---------- Writing recipes (Create, Update, Delete) ----------

// Turns "General Tso's Chicken" into "general-tso-s-chicken", then adds -2, -3, ...
// if that slug is already used (recipe_titles.slug is UNIQUE).
function make_unique_slug(mysqli $conn, string $title): string {
  $base = strtolower(trim(preg_replace('/[^A-Za-z0-9]+/', '-', $title), '-'));
  $base = substr($base, 0, 90);
  if ($base === '') {
    $base = 'recipe';
  }

  $slug = $base;
  $number = 2;
  while (true) {
    $result = mysqli_execute_query($conn, 'SELECT 1 FROM recipe_titles WHERE slug = ?', [$slug]);
    if (mysqli_fetch_row($result) === null) {
      return $slug;
    }
    $slug = $base . '-' . $number;
    $number++;
  }
}

// Replaces a recipe's ingredient rows with the new list.
// Used by both create and update, always inside their transaction.
function save_ingredients(mysqli $conn, int $recipe_id, array $ingredients): void {
  // Bounded delete: only this recipe's ingredients.
  mysqli_execute_query($conn, 'DELETE FROM ingredients WHERE recipe_id = ?', [$recipe_id]);

  $position = 1;
  foreach ($ingredients as $ingredient) {
    mysqli_execute_query(
      $conn,
      'INSERT INTO ingredients (recipe_id, position, ingredient) VALUES (?, ?, ?)',
      [$recipe_id, $position, $ingredient]
    );
    $position++;
  }
}

// An empty optional field is stored as NULL, not as ''.
function null_if_empty(string $value): ?string {
  return $value === '' ? null : $value;
}

// CREATE: one recipe is spread over several tables, so all the inserts happen
// in a transaction. If any of them fails, rollback undoes the others and the
// database never ends up with half a recipe. Returns the new recipe id.
function create_recipe(mysqli $conn, array $recipe): int {
  mysqli_begin_transaction($conn);
  try {
    // The parent row first; its AUTO_INCREMENT id links every other table.
    mysqli_execute_query($conn, 'INSERT INTO recipes (image_folder, source_pdf) VALUES (NULL, NULL)');
    $recipe_id = (int) mysqli_insert_id($conn);

    mysqli_execute_query(
      $conn,
      'INSERT INTO recipe_titles (recipe_id, title, slug, subtitle) VALUES (?, ?, ?, ?)',
      [$recipe_id, $recipe['title'], make_unique_slug($conn, $recipe['title']), null_if_empty($recipe['subtitle'])]
    );

    mysqli_execute_query(
      $conn,
      'INSERT INTO recipe_info (recipe_id, category_id, servings, description, main_image) VALUES (?, ?, ?, ?, ?)',
      [$recipe_id, $recipe['category_id'], $recipe['servings'], $recipe['description'], null_if_empty($recipe['main_image'])]
    );

    save_ingredients($conn, $recipe_id, $recipe['ingredients']);

    mysqli_commit($conn);
    return $recipe_id;
  } catch (mysqli_sql_exception $e) {
    mysqli_rollback($conn);
    throw $e;
  }
}

// UPDATE: same idea, every UPDATE is limited to this recipe with WHERE recipe_id = ?.
// The slug is left alone so the recipe's URL-friendly name stays stable.
function update_recipe(mysqli $conn, int $recipe_id, array $recipe): void {
  mysqli_begin_transaction($conn);
  try {
    mysqli_execute_query(
      $conn,
      'UPDATE recipe_titles SET title = ?, subtitle = ? WHERE recipe_id = ?',
      [$recipe['title'], null_if_empty($recipe['subtitle']), $recipe_id]
    );

    mysqli_execute_query(
      $conn,
      'UPDATE recipe_info SET category_id = ?, servings = ?, description = ?, main_image = ? WHERE recipe_id = ?',
      [$recipe['category_id'], $recipe['servings'], $recipe['description'], null_if_empty($recipe['main_image']), $recipe_id]
    );

    save_ingredients($conn, $recipe_id, $recipe['ingredients']);

    mysqli_commit($conn);
  } catch (mysqli_sql_exception $e) {
    mysqli_rollback($conn);
    throw $e;
  }
}

// DELETE: removes exactly one recipe, never an unbounded DELETE.
// Every child table (titles, info, ingredients, steps, tips, tools...) has
// ON DELETE CASCADE on its foreign key to recipes.id, so MySQL removes those
// rows too. Returns false if no recipe had that id.
function delete_recipe(mysqli $conn, int $recipe_id): bool {
  mysqli_execute_query($conn, 'DELETE FROM recipes WHERE id = ?', [$recipe_id]);
  return mysqli_affected_rows($conn) === 1;
}
