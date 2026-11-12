<?php
declare(strict_types=1);
// login.php - the admin log in form.
// AI: generated with Claude based on the week 6 lecture snippets (carried over from Alpha,
// moved onto the shared header/footer for beta).

require __DIR__ . '/session.php';
require __DIR__ . '/functions.php';

// Already logged in? Go straight to the admin area.
if (isset($_SESSION['user_id'])) {
  header('Location: admin/index.php');
  exit;
}

// config.php creates the connection and returns it.
$conn = require __DIR__ . '/../assets/database/config.php';

$error = '';
$email = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  // Lecture: "Login: look up by email, then verify"
  // Prepared statement (mysqli_execute_query prepares, binds and executes in one call),
  // and the password is never part of the WHERE clause.
  $email = trim(input_string($_POST, 'email'));
  $plain = input_string($_POST, 'password');

  $result = mysqli_execute_query(
    $conn,
    'SELECT id, password_hash FROM users WHERE email = ?',
    [$email]
  );
  $user = mysqli_fetch_assoc($result);

  // Verify the password, then "Prevent session fixation".
  // password_verify() re-hashes $plain with the salt stored in the hash and
  // compares in constant time. session_regenerate_id(true) swaps to a new
  // session id and deletes the old one, so a planted id becomes worthless.
  if ($user !== null && password_verify($plain, $user['password_hash'])) {
    session_regenerate_id(true);

    // Store ONLY the user id. Everything else is looked up from the database.
    $_SESSION['user_id'] = (int) $user['id'];

    header('Location: admin/index.php');
    exit;
  }

  // One vague message for both "no such email" and "wrong password",
  // so nobody can use this form to find out which emails are registered.
  $error = 'Invalid email or password.';
}

$page_title = 'Log in';
$root = '';
require __DIR__ . '/partials/header.php';
?>

  <form class="auth-form" method="post">
    <h2>Admin log in</h2>

    <?php if ($error !== ''): ?>
      <p class="auth-error"><?= htmlspecialchars($error) ?></p>
    <?php endif; ?>

    <label>
      Email
      <input type="email" name="email" required value="<?= htmlspecialchars($email) ?>">
    </label>

    <label>
      Password
      <input type="password" name="password" required>
    </label>

    <button type="submit">Log in</button>
  </form>

<?php require __DIR__ . '/partials/footer.php'; ?>
