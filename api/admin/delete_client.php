<?php
include_once '../config/cors.php';
include_once '../config/db.php';
include_once '../auth/verify.php';

$database = new Database();
$db = $database->getConnection();
$user = verifyToken($db, 'admin');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"));
    if(!empty($data->client_id)) {
        $stmt = $db->prepare("DELETE FROM users WHERE id = :id AND role = 'client'");
        $stmt->bindParam(':id', $data->client_id);

        if($stmt->execute()){
            echo json_encode(["message" => "Client deleted successfully."]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Failed to delete client."]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["message" => "Incomplete data."]);
    }
}