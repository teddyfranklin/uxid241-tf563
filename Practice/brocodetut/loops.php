<?php
    // for loop = repeat some code a certain # of times
    // accepts three statements
        // counter (i = 0)
        // stopping condition  (i < 5)
        // increment amount
    
        /*
        for($i = 0;$i <= 100;$i+=3){
        echo $i . "<br>";
        }
        */

    /*
        // while loops take no statements and can run infinitely

        $seconds = 0;
            while($running){
            if(isset($_POST["stop"])){
                $running = false;
            }
            else{
                $seconds++;
                echo $seconds . "<br>";
            }
        }  
    */
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <form action="loops.php" method="post">
        <label>Enter a number to count to:</label>
        <input type="text" name="counter">
        <input type="submit" name="click">
    </form>
    <?php
    $counter = $_POST["counter"];

    for($i = 0; $i <= $counter; $i++){
        echo $i . "<br>";
    }
    ?>
    
</body>
</html>
