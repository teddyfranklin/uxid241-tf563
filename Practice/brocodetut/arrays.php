<?php

    // array = "variable" which can hold more than one value at one time

    // it is much easier to work with an array than with several variables

    $foods = array("apple", "orange", "banana", "coconut");

    /*
    // this is the inefficient way to print an array
    echo $foods[0] . "<br>";
    echo $foods[1] . "<br>";
    echo $foods[2] . "<br>";
    echo $foods[3] . "<br>";
    */
    
    // this changes the array at the indexed value to the inputted string
    // $foods[0] = "pineapple";

    // this adds an element to the end of an array
    // array_push($foods, "strawberry", "kiwi");

    // removes the last element of your array
    // array_pop($foods);

    // this removes the first element of your array then shifts all elements by one
    // array_shift($foods);

    // reverses the order of an array by returning a new one 
    // $reversed_foods = array_reverse($foods);

    foreach($foods as $food){
        echo $food . "<br>";
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
    <form action="arrays.php" method="post">
        <label>Enter a country</label>
        <input type="text" name="country">
        <input type="submit">
    </form>
</body>
</html>
<?php
    // Associative array = An array made of key=>value pairs

    $capitals = array("USA"=>"DC", 
                    "Japan"=>"Kyoto", 
                    "Korea"=>"Seoul", 
                    "India"=>"New Delhi");
    
    $capital = $capitals[$_POST["country"]  ?? ''];
    echo"The capital is {$capital} <br>";
    
    // updates the value of a key
    // $capitals["USA"] = "Las Vegas";

    // adds a new key value pair
    // $capitals["China"] = "Beijing";

    // removes the last pair in this array
    // array_pop($capitals);

    // removes first pair
    // array_shift($capitals);

    // returns a new array of keys
    // $keys = array_keys($capitals);

    // returns a new array of values
    // $values = array_values($capitals);

    // returns a new associative array with keys and values flipped
    // $capitals = array_flip($capitals);

    foreach($capitals as $key => $value){
        echo"{$key} = {$value} <br>";
    }

?>