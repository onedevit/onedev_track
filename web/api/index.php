<?php
// Simple API Health Check
header("Content-Type: application/json; charset=UTF-8");
echo json_encode([
    "status" => "success",
    "message" => "Welcome to OneDev Track API",
    "version" => "1.0.0"
]);
