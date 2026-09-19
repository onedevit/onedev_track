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
        if(password_verify($data->password, $row['password'])){
            $token = bin2hex(random_bytes(32));

            $update_query = "UPDATE users SET token = :token WHERE id = :id";
            $update_stmt = $db->prepare($update_query);
            $update_stmt->bindParam(':token', $token);
            $update_stmt->bindParam(':id', $row['id']);
            $update_stmt->execute();

            http_response_code(200);
            echo json_encode([
                "token" => $token,
                "role" => $row['role'],
                "user_id" => $row['id']
            ]);
        } else {
            http_response_code(401);
            echo json_encode(["message" => "Invalid credentials."]);
        }
    } else {
        http_response_code(401);
        echo json_encode(["message" => "Invalid credentials."]);
    }
} else {
    http_response_code(400);
    echo json_encode(["message" => "Incomplete data."]);
}
