<?php
include_once '../config/cors.php';
include_once '../config/db.php';

$database = new Database();
$db = $database->getConnection();
$data = json_decode(file_get_contents("php://input"));

if(!empty($data->username) && !empty($data->password)){
    $query = "SELECT id, username, password, role FROM users WHERE username = :username LIMIT 1";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':username', $data->username);
    $stmt->execute();

    if($stmt->rowCount() > 0){
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        $is_valid = password_verify($data->password, $row['password']);

        echo json_encode([
            "debug" => true,
            "provided_username" => $data->username,
            "provided_password" => $data->password,
            "db_hash" => $row['password'],
            "is_valid" => $is_valid
        ]);

    } else {
        echo json_encode(["debug" => true, "message" => "User not found in DB."]);
    }
} else {
    echo json_encode(["debug" => true, "message" => "Incomplete data.", "received" => $data]);
}