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

  // Image path: optional. It is no longer typed by the admin: it is either the path already
  // stored for this recipe (carried in a hidden field) or filled in by the upload code after
  // the file passes validate_image_upload(). Either way it must have the stored shape
  // ("images/<folder>/<file>" or "uploads/<file>") with no ".." so it can't escape assets/.
  if ($recipe['main_image'] !== '') {
    if (mb_strlen($recipe['main_image']) > 255
        || !preg_match('#^(images|uploads)/[A-Za-z0-9._/-]+$#', $recipe['main_image'])
        || str_contains($recipe['main_image'], '..')) {
      $errors['main_image'] = 'That image path is not valid. Upload a new image instead.';
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

// ---------- Recipe image upload (week 8) ----------
// In $_FILES only tmp_name, size and error come from PHP. 'name' and 'type' come from the
// visitor's browser, so they are never trusted for the type or the extension.

// Where uploads live: assets/uploads/, served by the web server as a plain static file.
// That folder has an .htaccess that denies PHP-type files, so it can only hold inert data.
const UPLOAD_DIR = __DIR__ . '/../assets/uploads';
const UPLOAD_MAX_BYTES = 2 * 1024 * 1024; // 2 MB
// Allowlist: real MIME type (read from the file's bytes) => the only extension we will save it under.
const UPLOAD_ALLOWED_TYPES = [
  'image/jpeg' => 'jpg',
  'image/png' => 'png',
  'image/webp' => 'webp',
];

// Gates 1-4 from the lecture. Returns [$ext, $error]: $ext is the verified extension when the
// file is acceptable, otherwise $error says why not. Nothing is moved or written here.
function validate_image_upload(array $file): array {
  // Gate 1: PHP reports whether the transfer worked. (UPLOAD_ERR_NO_FILE is handled by the caller.)
  $error_code = $file['error'] ?? UPLOAD_ERR_NO_FILE;
  if ($error_code === UPLOAD_ERR_INI_SIZE || $error_code === UPLOAD_ERR_FORM_SIZE) {
    return [null, 'That image is too large. The limit is 2 MB.'];
  }
  if ($error_code !== UPLOAD_ERR_OK) {
    return [null, 'The upload did not finish. Please try again.'];
  }

  // Gate 2: size limit, checked in code as well as in php.ini.
  $size = $file['size'] ?? 0;
  if (!is_int($size) || $size <= 0 || $size > UPLOAD_MAX_BYTES) {
    return [null, 'That image is too large. The limit is 2 MB.'];
  }

  // Gate 3: the REAL type, read from the file's magic bytes. $file['type'] is ignored.
  $tmp_name = $file['tmp_name'] ?? '';
  if (!is_string($tmp_name) || $tmp_name === '' || !is_uploaded_file($tmp_name)) {
    return [null, 'The upload could not be verified. Please try again.'];
  }
  $finfo = new finfo(FILEINFO_MIME_TYPE);
  $mime = $finfo->file($tmp_name);
  if ($mime === false || !array_key_exists($mime, UPLOAD_ALLOWED_TYPES)) {
    return [null, 'Only JPEG, PNG or WebP images are allowed.'];
  }
  // Extra check: the bytes must also parse as an actual image (a text file with a fake header won't).
  if (@getimagesize($tmp_name) === false) {
    return [null, 'That file is not a valid image.'];
  }

  // Gate 4: the extension comes from the verified MIME, never from the client's file name.
  return [UPLOAD_ALLOWED_TYPES[$mime], null];
}

// Gate 5: a safe, readable, unique file name. The client's name is hostile input: keep only
// lowercase letters and digits, collapse everything else (dots, slashes, spaces) to "-".
function make_safe_name(string $original_name, string $ext, string $folder): string {
  $base = strtolower(pathinfo($original_name, PATHINFO_FILENAME));
  $base = preg_replace('/[^a-z0-9]+/', '-', $base);
  $base = substr(trim($base, '-'), 0, 60);
  if ($base === '') {
    $base = 'upload';
  }
  $safe_name = $base . '.' . $ext;
  $counter = 1;
  while (file_exists($folder . '/' . $safe_name)) {
    $safe_name = $base . '-' . $counter . '.' . $ext;
    $counter++;
  }
  return $safe_name;
}

// Gate 6: validate, name and move the file. Returns [$path, $error]. $path is what goes in
// recipe_info.main_image, relative to assets/ (e.g. "uploads/pasta.jpg").
function save_recipe_image(array $file): array {
  [$ext, $error] = validate_image_upload($file);
  if ($error !== null) {
    return [null, $error];
  }
  if (!is_dir(UPLOAD_DIR)) {
    return [null, 'The image could not be saved. Please try again.'];
  }
  $name = make_safe_name((string) $file['name'], $ext, UPLOAD_DIR);
  // move_uploaded_file (not rename/copy) re-confirms this file really came from this POST.
  if (!move_uploaded_file($file['tmp_name'], UPLOAD_DIR . '/' . $name)) {
    return [null, 'The image could not be saved. Please try again.'];
  }
  return ['uploads/' . $name, null];
}

// Deletes a file we stored in assets/uploads/ (used when an upload is replaced, or the DB write
// fails after the file was already saved). Only touches "uploads/<plain name>" paths.
function delete_uploaded_image(?string $path): void {
  if ($path !== null && preg_match('#^uploads/([a-z0-9-]+\.(jpg|png|webp))$#', $path, $m) === 1) {
    @unlink(UPLOAD_DIR . '/' . $m[1]);
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
  $existing = get_recipe($conn, $recipe_id);
  mysqli_execute_query($conn, 'DELETE FROM recipes WHERE id = ?', [$recipe_id]);
  $deleted = mysqli_affected_rows($conn) === 1;
  if ($deleted && $existing !== null) {
    delete_uploaded_image($existing['main_image']); // only removes files inside assets/uploads/
  }
  return $deleted;
}
