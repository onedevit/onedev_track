<?php
include_once '../config/cors.php';
include_once '../config/db.php';
include_once '../auth/verify.php';

$database = new Database();
$db = $database->getConnection();
$user = verifyToken($db, 'admin');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"));

    if(!empty($data->task_id) && !empty($data->title)) {
        $title = $data->title;
        $desc = isset($data->description) ? $data->description : '';
        $notes = isset($data->notes) ? $data->notes : null;

        if ($notes !== null) {
            $query = "UPDATE tasks SET title = :title, description = :description, notes = :notes WHERE id = :id";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':notes', $notes);
        } else {
            $query = "UPDATE tasks SET title = :title, description = :description WHERE id = :id";
            $stmt = $db->prepare($query);
        }

        $stmt->bindParam(':title', $title);
        $stmt->bindParam(':description', $desc);
        $stmt->bindParam(':id', $data->task_id);

        if($stmt->execute()){
            echo json_encode(["message" => "Task updated successfully."]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Unable to update task."]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["message" => "Incomplete data."]);
    }
}