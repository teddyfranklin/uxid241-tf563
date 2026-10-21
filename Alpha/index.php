<?php
declare(strict_types=1);
include $_SERVER['DOCUMENT_ROOT']."/assets/database/config.php";

function printRecipeTitles(mysqli $connection): void {
    $result = mysqli_query($connection, "SELECT title FROM recipes_flat ORDER BY recipe_id");
    while ($row = mysqli_fetch_assoc($result)) {
        echo htmlspecialchars($row['title']) . "<br />";
    }
}

/*
you're not enumerating the row id here. this just prints the same title a bunch of times
don't write the echo loop inside of the function. return it as an array and echo it inside of the html

function printRecipeTest(mysqli $connection): void {
    $result2 = mysqli_query($connection, "SELECT subtitle FROM recipes_flat ORDER BY recipe_id");
    $row = mysqli_fetch_assoc($result2);
    echo "<br />";
    for ($i = 0; $i < 20; $i++){
        echo htmlspecialchars($row['subtitle']) . '<br />';
    }
}
*/

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
    <?php printRecipeTitles($connection); ?>
</body>
</html>