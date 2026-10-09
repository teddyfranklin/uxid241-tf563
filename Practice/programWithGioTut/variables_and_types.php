<?php
// Constants 
// constants are values which cannot change
// Use this for data that doesn't change very option

// constants created with define are defined at runtime. Can be defined in control structure.  s
define('name', 'value');
echo name;

// constants created with const are defined at compile time. Cannot be defined in control structure (such as if statements that would define the constant).
const status_paid = 'paid';
echo status_paid . '<br />';

// checks if value is constant
echo defined('name');

// magic constants change depending on context
//  echo __LINE__; prints line number
//  echo __FILE__; prints fullfile path 


// Variable Variables
// takes the value of the variable and treats that as the name of a new variable

$foo = 'bar';

$$foo = 'baz';
// is the same as
$bar = 'baz';
?>

<?php

/* Data Types & Type Casting */


# 4 Scalar Types
    # bool - true or false
        # anything empty evaluates to false
    $complete = true;
    # int - whole numbers
        # you can pass an integer into a float type and not receive any error.
    $score = 7;
    # float - decimals
    $price = .87;
    # string - series of characters
        # single quotes cannot use variables
        # heredoc and nowdoc are used to submit multiline strings. Can input HTML into these.
    $hello = 'hiiii';

# 4 Compound Types
    # array - list of items that can be multiple data types
    $companies = [1, 'A', true];
    # object
    # callable
    # iterable

# 2 Special Types
    # resource
    # null
        # use when you need to define a variable that will be assigned value through a control structure

?>