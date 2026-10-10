<?php
// unary operators: expects one value
// binary operators: expects two values
// ternary operators: expects three values

$x = 'hello';
$y = 7;
$z = null;

// precedence:
    // https://www.php.net/manual/en/language.operators.precedence.php

    // Because operators are combined to create complicated expressions, precedence determines the order in which they operate. Think PEMDAS.
    // Using parenthesis forces precedence 

    // Associativity determines how operators with the same precedence are grouped.



// arithmetic operators [+ - * / % **]
    
    // these do math


// assignment operators [= += -= *= /= %= **=]

    // these assign values


// string operators [. .=]

    // these concat strings


// comparison operators [= == === != !== !=== < > <= >= ?? ?:]

    // these compare values

        // ternary operator: shorthand for an if else statement. Expression after ? is evaluated if $y = 7 is true. 
        $result = $y === 7 ? 'That jawn is 7' : 'That jawn isnt 7';

        // null coalescing operators: evaluates expression if value is null. helpful for evaluating undefined array keys
        $a = $z ?? 'hello';


// error control operators [@]

    // supresses errors from an expression depending on error configuration


// increment/decrement operators

    // increments on a value
    $b = 4;

        //post: returns value, then increments
        $b++;
        $b--;

        //pre: increments, then returns value
        ++$b;
        --$b;


// logical operators [&& || ! and or xor]
    $c = true;
    $d = false;

    // &&: both must be true
    var_dump($c && $d);

    // ||: one must be true
        // PHP logic operators don't evaluate the second value if the first value is true. 

// bitwise operators

    // alters binary. useful for encryption.


// array operators [+ = === !==  ]
    
    // operate on arrays
    $one = ['a' => 1, 'b' => 2, 'c' => 3];
    $two = ['a' => 1, 'b' => 2, 'c' => 3];

    // evaluates if arrays are the same or have the same key=>value pairs
    $three = $one == $two;
    var_dump($three);

// execution operators

// type operators (instanceof)

// nullsafe operator


?>