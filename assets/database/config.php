<?php
declare(strict_types=1);

// Default credentials for each local server.
// XAMPP (Windows): root with no password on port 3306
// MAMP (Mac): root/root on port 8889
if (PHP_OS_FAMILY === 'Windows') {
    $db_user = "root";
    $db_password = '';
    $db_port = 3306;
} else {
    $db_user = "root";
    $db_password = 'root';
    $db_port = 8889;
}

$db_server = "127.0.0.1";
$db_name = 'recipe_db';

// Optional per-machine overrides (gitignored). Copy config.local.example.php to config.local.php to use.
if (file_exists(__DIR__ . "/config.local.php")) {
    require __DIR__ . "/config.local.php";
}

$connection = mysqli_connect($db_server, $db_user, $db_password, $db_name, $db_port);

// Only print a message when the connection fails. Printing "you are connected"
// on success would also show up inside the search results that search.js loads.
if(!$connection){
    echo"you are not connected <br />";
}

return $connection;
