<?php
include_once '../config/cors.php';
include_once '../config/db.php';
include_once '../auth/verify.php';

$database = new Database();
$db = $database->getConnection();
$user = verifyToken($db, 'admin');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"));

    if(!empty($data->project_id)) {
        $query = "DELETE FROM projects WHERE id = :id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':id', $data->project_id);

        if($stmt->execute()){
            echo json_encode(["message" => "Project deleted successfully."]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Unable to delete project."]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["message" => "Incomplete data."]);
    }
}