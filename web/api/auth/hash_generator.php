<?php
header("Content-Type: application/json; charset=UTF-8");
$password = 'admin123';
$hash = password_hash($password, PASSWORD_BCRYPT);
echo json_encode([
    "password" => $password,
    "hash" => $hash,
    "verify_test" => password_verify($password, $hash)
]);