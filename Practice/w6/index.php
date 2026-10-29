<?php

declare(strict_types=1);
$conn = require '../inc/db.php';
require '../inc/functions.php';

$result = mysqli_execute_query($cinn, 'SELECT email FROM users WHERE id = ?', 
[$_SESSION[user_id]]

);


