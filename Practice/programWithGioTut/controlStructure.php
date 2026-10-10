<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <?php $score = 75;?>
    <?php if ($score > 89): ?>
        <strong>A</strong>
    <?php elseif ($score > 79): ?>
        <strong>B</strong>
    <?php endif ?>
</body>
</html>



<?php
    //  Loops

    // while
    // run code loop while condition is true. can easily run infinitely. can also not run at all if condition is never true.
    // use cases: waiting for something to happen then breaking. something that might not need to run at all.
    $i = 0;
        while (true) {
            while ($i > 10) {
                break 2;
            }
            echo $i++;
    }

    // do-while

    // for

    // foreach
?>

