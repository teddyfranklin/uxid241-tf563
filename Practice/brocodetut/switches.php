<?php

    // replacement for using many elif statements

    function pickGrade($grade){
    switch($grade){
        case "A":
            echo"You did great";
            break;
        case "B":
            echo"You did good";
            break;
        case "C":
            echo"You did okay";
            break;
        case "D":
            echo"You did not great";
            break;
        case "F":
            echo"You failed";
            break;
        }
    }

    function pickDate($date){
        switch($date){
            case "Monday":
                echo "I hate Mondays";
                break;
            case "Tuesday":
                echo "ITS TACOO TUESDAYYY";
                break;
            case "Wednesday":
                echo "ITS TACOO TUESDAYYY";
                break;
            case "Thursday":
                echo "ITS TACOO TUESDAYYY";
                break;
            case "Friday":
                echo "ITS TACOO TUESDAYYY";
                break;
        }
    }
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hee HEe Hoo Hoo</title>
</head>
<body>
    <form action="switches.php" method="post">
        <label>Input grade</label>
        <input type="text" name="grade">
        <input type="submit" name="click">
</form>
    <?php
        // ?? is the null coalescing operator. It means “use the left side if it exists, otherwise use the right side”:
        $grade = $_POST["grade"] ?? "";
        pickGrade($grade);
    ?>
    <form action="switches.php" method="post">
        <label>Input date</label>
        <input type="text" name="date">
        <input type="submit" name="click">
    </form> 
    <?php
        $date = $_POST["date"] ?? "";
        pickDate($date);
    ?>
</body>
</html>