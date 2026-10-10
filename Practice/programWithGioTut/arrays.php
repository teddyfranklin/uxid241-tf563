<?php
// Arrays are lists of values of any type


$foods = ['Apple', 'Banana', 'Cabbage'];

echo $foods[1];
echo '<br />';

// 'undefined array key' happens when you try to access a key that doesn't exist

// this checks if a key exists at a specific value
var_dump(isset($foods[3]));
echo '<br />';


// this prints the array keys in order
print_r($foods);
echo '<br />';


// two methods of pushing array elements
$foods[] = 'Dirkus';
array_push($foods, 'Donuts', 'Eggs');

$associativeFoods = [
    'Apple' => 'fire',
    'Banana' => 'fire'
];
print_r($associativeFoods);
echo '<br />';


// you can use the syntax below to push a new element and alter its value
$newFood = 'fries';
$associativeFoods[$newFood] = 'super fire';
print_r($associativeFoods);
echo '<br />';


// Multidimensional arrays have arrays as elements. You can nest these infinitely.
$multiFoods = [
    'languages' => [
        'creator' => '',
        'extension' => 'bruhmoment',
        'isOpenSource' => true,
        'versions' => [
            ['version' => 1, 'releaseDate' => 'October 8th, 2026'],
            ['version' => 1.1, 'releaseDate' => 'October 9th, 2026'],
        ],
    ],
    'sweets' => [
        'donut' => 'fire',
        'sour patch kids' => 'nice',
        'cakes' => [
            'chocolate' => true,
            'vanilla' => false,
        ],
    ]
];

// accessing nested arrays
echo $multiFoods['sweets']['cakes']['chocolate'];

?>