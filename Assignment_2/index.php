<?php
    declare(strict_types=1);
    // i procrastinated this assignment and vibecoded this so i can at least show you something. suppose it's time to work on my time management.

    // Checks for data type and value
    function trim_value(string $key): string {
        $value = $_GET[$key] ?? '';
        return is_string($value) ? trim($value) : '';
    }

    // Ensures no special characters are sent to backend. Sanitization.
    function e(string $value): string {
        return htmlspecialchars($value, ENT_QUOTES, 'UTF-8');
    }

    // Trimmed name without special chars
    $name = trim_value('name');

    $errors    = [];
    $submitted = isset($_GET['submitted']);

    // Validation and error submission
    if ($submitted) {
        // Recipe name: required, max 50 characters
        if ($name === '') {
            $errors['name'] = 'Recipe name is required.';
        } elseif (mb_strlen($name) > 50) {
            $errors['name'] = 'Recipe name must be 50 characters or fewer.';
        }
    }

    $success = $submitted && count($errors) === 0;
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>UXID 241 Assignment 2</title>
</head>
<body>
    <?php if ($success): ?>
        <h2>Recipe saved</h2>
        <p>
            <strong><?= e($name) ?></strong>
        </p>
    <?php elseif ($submitted): ?>
        <p>Invalid Submission.</p>
    <?php endif; ?>

    <form action="index.php" method="get" novalidate>
        <input type="hidden" name="submitted" value="1" />

        <p>
            <label for="name">Recipe Name</label>
            <input type="text" id="name" name="name" value="<?= e($name) ?>" />
            <?php if (isset($errors['name'])): ?>
                <span><?= e($errors['name']) ?></span>
            <?php endif; ?>
        </p>

        <button type="submit">Submit</button>
    </form>
</body>
</html>
