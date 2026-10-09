<?php
// don't use this for assignments. 

// check for null and trim spaces
function get_value(string $key): string {
    return trim($_GET($key) ?? '');
}

// exit if special characters exist in input
function e(string $value): string {
    return htmlspecialchars($value, ENT_QUOTES, 'UTF-8');
}

// recipe list
$recipes = [
    'Tacos al Pastor',
    'Fish tacos',
    'Pad Thai',
    'Butterdogs'
];

// initialize 
$q = get_value('q');
$results = [];

if ($q !== '') {
    foreach($recipes as $recipe) {
        if (str_contains(strtolower($recipe), strtolower($q))) {
            $results[] = $recipe;
        }
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
    <h1>"search recipes"</h1>
    <form action "w2ex1.php" method="get">
        <label> </label>
    </form>



    <?php if ($q !== '') : //if q isn't null?>
        <p></p>
</body>
</html>