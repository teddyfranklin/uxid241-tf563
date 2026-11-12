<?php
declare(strict_types=1);
// recipe_form.php - the form shared by admin/create.php and admin/edit.php.
// AI: generated with Claude Code (entire file).
//
// The page that includes this sets:
//   $recipe        the values to show in the fields (blank, from the database, or what was just submitted)
//   $errors        field name => message from validate_recipe()
//   $categories    every category, for the dropdown
//   $form_action   where the form posts to
//   $submit_label  text on the button
//
// Every value printed into the form goes through htmlspecialchars, including the
// values the admin just typed, so nothing they submit can turn into HTML.
?>
  <form class="recipe-form" method="post" action="<?= htmlspecialchars($form_action) ?>" novalidate>
    <?php if (isset($errors['form'])): ?>
      <p class="auth-error"><?= htmlspecialchars($errors['form']) ?></p>
    <?php endif; ?>

    <label>
      Title
      <input type="text" name="title" maxlength="255" required value="<?= htmlspecialchars((string) $recipe['title']) ?>">
      <?php if (isset($errors['title'])): ?><span class="field-error"><?= htmlspecialchars($errors['title']) ?></span><?php endif; ?>
    </label>

    <label>
      Subtitle <span class="optional">(optional)</span>
      <input type="text" name="subtitle" maxlength="255" value="<?= htmlspecialchars((string) $recipe['subtitle']) ?>">
      <?php if (isset($errors['subtitle'])): ?><span class="field-error"><?= htmlspecialchars($errors['subtitle']) ?></span><?php endif; ?>
    </label>

    <label>
      Category
      <select name="category_id" required>
        <option value="">Choose a category</option>
        <?php foreach ($categories as $category): ?>
          <option value="<?= (int) $category['id'] ?>" <?= (string) $recipe['category_id'] === (string) $category['id'] ? 'selected' : '' ?>>
            <?= htmlspecialchars($category['name']) ?>
          </option>
        <?php endforeach; ?>
      </select>
      <?php if (isset($errors['category_id'])): ?><span class="field-error"><?= htmlspecialchars($errors['category_id']) ?></span><?php endif; ?>
    </label>

    <label>
      Servings
      <input type="number" name="servings" min="1" max="20" step="1" required value="<?= htmlspecialchars((string) $recipe['servings']) ?>">
      <?php if (isset($errors['servings'])): ?><span class="field-error"><?= htmlspecialchars($errors['servings']) ?></span><?php endif; ?>
    </label>

    <label>
      Description
      <textarea name="description" rows="5" required><?= htmlspecialchars((string) $recipe['description']) ?></textarea>
      <?php if (isset($errors['description'])): ?><span class="field-error"><?= htmlspecialchars($errors['description']) ?></span><?php endif; ?>
    </label>

    <label>
      Ingredients <span class="optional">(one per line)</span>
      <textarea name="ingredients" rows="8" required><?= htmlspecialchars(implode("\n", $recipe['ingredients'])) ?></textarea>
      <?php if (isset($errors['ingredients'])): ?><span class="field-error"><?= htmlspecialchars($errors['ingredients']) ?></span><?php endif; ?>
    </label>

    <label>
      Image path <span class="optional">(optional, e.g. images/my-recipe/dish.jpg)</span>
      <input type="text" name="main_image" maxlength="255" value="<?= htmlspecialchars((string) $recipe['main_image']) ?>">
      <?php if (isset($errors['main_image'])): ?><span class="field-error"><?= htmlspecialchars($errors['main_image']) ?></span><?php endif; ?>
    </label>

    <div class="form-actions">
      <button type="submit"><?= htmlspecialchars($submit_label) ?></button>
      <a href="index.php">Cancel</a>
    </div>
  </form>
