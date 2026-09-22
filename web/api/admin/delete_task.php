<?php
include_once '../config/cors.php';
include_once '../config/db.php';
include_once '../auth/verify.php';

$database = new Database();
$db = $database->getConnection();
$user = verifyToken($db, 'admin');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"));

    if(!empty($data->task_id)) {
        // الحذف المرجعي (CASCADE) سيقوم بحذف المهام الفرعية تلقائياً بفضل قاعدة البيانات التي أعددناها
        $query = "DELETE FROM tasks WHERE id = :id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':id', $data->task_id);

        if($stmt->execute()){
            echo json_encode(["message" => "Task deleted successfully."]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Unable to delete task."]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["message" => "Incomplete data."]);
    }
}