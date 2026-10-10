<?php
// isset() = returns true if a variable is filled and not null
// empty() = returns true if a variable is not declared

$username = null;

if(isset($username)){
    echo"variable is set";
}
else{
    echo"not set";
}

?>