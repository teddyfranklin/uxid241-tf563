<?php
declare(strict_types=1);

$db_server = "127.0.0.1";
$db_user = "root";
$db_password = 'root';
$db_name = 'recipe_db';
$db_port = 8889;
$connection = '';

$connection = mysqli_connect($db_server, $db_user, $db_password, $db_name, $db_port);

if($connection){
    echo"you are connected <br />";
} else {
    echo"you are not connected <br />";
}

?>