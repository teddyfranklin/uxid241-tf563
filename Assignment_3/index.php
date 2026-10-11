<?php
declare(strict_types=1);
include $_SERVER['DOCUMENT_ROOT']."/assets/database/database.php";


function printRowNumber(mysqli $connection): void {
    $result = mysqli_query($connection, "SELECT COUNT(*) AS total FROM recipes_flat");
    $row = mysqli_fetch_assoc($result);
    echo "Rows: " . $row['total'];   // should print 40
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Assignment 3</title>
</head>
<body>
    <h1>Recipes list:</h1>
    <?php printRowNumber($connection); ?>
</body>
</html>