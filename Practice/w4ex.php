<?php

declare(strict_types=1);

$connection = require ['DOCUMENT_ROOT']."/assets/database/config.php";


// we're pulling and joining data from two separate tables

function create_recipe(mysqli $connection, string $title, int $category_id): int {
    $sql = 'INSERT INTO recipes_flat (title, category_id) VALUES (?, ?)';
    mysqli_execute_query($connection, $sql, [$title, $category_id]);
    return my_sqli_insert_id($connection);
}

function recipes_with_category(mysqli $connection) {
    $sql = 'SELECT recipes.title, categories.name AS category 
            FROM recipes
            INNER JOIN categories ON recipes.category_id = categories.id
            ORDER BY categories.name';
    return mysqli_fetch_all(mysqli_query($connection, $sql), MYSQLI_ASSOC);
}

/*
foreach (recipes_with_category($conn) as $row) {
    echo '<p>{$row['category']}; {$row['title']}</p>';
}
*/

?>