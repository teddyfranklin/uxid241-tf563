<?php
declare(strict_types=1);
include $_SERVER['DOCUMENT_ROOT']."/assets/database/config.php";


function printRowNumber(mysqli $connection): void {
    $result = mysqli_query($connection, "SELECT COUNT(*) AS total FROM recipes_flat");
    $row = mysqli_fetch_assoc($result);
    echo "Rows: " . $row['total'];   // should print 40
}

function printRecipeTitles(mysqli $connection): void {
    $result = mysqli_query($connection, "SELECT title FROM recipes_flat ORDER BY recipe_id");
    while ($row = mysqli_fetch_assoc($result)) {
        echo htmlspecialchars($row['title']) . "<br />";
    }
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
    <br />
    <?php printRecipeTitles($connection); ?>
</body>
</html>