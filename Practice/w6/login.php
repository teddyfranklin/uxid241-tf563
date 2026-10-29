<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>

<?php
declare(strict_types=1)
$conn = require 'inc/db.php'
require 'inc/functions.php'

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = post_value('email');
    $plain = $_POST['password'] ?? '';
    $hash = password_hash($plain, PASSWORD_DEFAULT);

    mysqli_execute_query(
        $conn,
        'SELECT id, password_hash FROM users WHERE email = ?',
        [$email, $hash]
    );

    $user = mysqli_fetch_assoc($result);
    
    if ($user !== null && password_verify($plain, $user['password_hash'])) {
        session_regenerate_id(true);
        $_SESSION['user_id'] = $user['id'];
        header ('Location: admin/index.php');
        exit;
    }

    $error = 'Invalid email or password';
}

?>


<body>
    <form method="post">
        <input type="email" name ="email" placeholder="janedoe@gmail.com">
        <input type="password" name ="password" placeholder="janedoe@gmail.com">
        <button type="submit">Login</button>
    </form>
</body>
</html>