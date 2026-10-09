<?php

    //function myFunction($param) {
        // code to be executed
    //}

    // php -S localhost:8000 

    // && = true if both conditions are true
    // || = true if at least one condition is true
    // ! = true if false. false if true.

    function ageCheck($age) {
        if ($age > 21 && $age < 42 ) {
            echo "ur good";
        }
        else {
            echo "nah";
        }
    }
?>


<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <form action="logicOperators.php" method="post">
        <label>Input age:</label>
        <input type="text" name="age">
        <input type="submit" value="click">
    </form>
    <?php 
    $age = $_POST["age"];
    agecheck($age); 
    ?>
</body>
</html>