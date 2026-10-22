<?php
# you need to be comfortable seamlessly converting data types. 

# for images: make an images column containing image file paths and use implode/explode to separate them into individual photos. 

$id = get_value('id');

# this is how you add recipe steps to the database without making a separate table for them.
# you are essentially taking an array of disparaate variables and merging them into a single string. 
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $step_list = $_POST['step'] ?? [];
    if ($step_list !== []) {
        # implode converts separate variables into strings
        $steps = implode('*', $step_list);
        add_steps($conn, (int) $id, $steps);
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
<?php
    $recipe = get_recipe($conn, (int) $id);
    if ($recipe && $recipe['steps']);
?>

    
</body>
</html>