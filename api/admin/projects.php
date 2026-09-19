<?php
include_once '../config/cors.php';
include_once '../config/db.php';
include_once '../auth/verify.php';

$database = new Database();
$db = $database->getConnection();
$user = verifyToken($db, 'admin');

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $query = "SELECT p.*, u.username as client_name,
              (SELECT COUNT(*) FROM tasks WHERE project_id = p.id) as total_tasks,
              (SELECT COUNT(*) FROM tasks WHERE project_id = p.id AND status = 'completed') as completed_tasks
              FROM projects p
              JOIN users u ON p.client_id = u.id
              ORDER BY p.created_at DESC";
    $stmt = $db->prepare($query);
    $stmt->execute();
    echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"));
    if(!empty($data->title) && !empty($data->client_id) && !empty($data->start_date) && !empty($data->duration_days) && !empty($data->deadline)) {

        $query = "INSERT INTO projects (client_id, title, description, start_date, duration_days, deadline) VALUES (:client_id, :title, :description, :start_date, :duration_days, :deadline)";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':client_id', $data->client_id);
        $stmt->bindParam(':title', $data->title);
        $desc = isset($data->description) ? $data->description : '';
        $stmt->bindParam(':description', $desc);
        $stmt->bindParam(':start_date', $data->start_date);
        $stmt->bindParam(':duration_days', $data->duration_days);
        $stmt->bindParam(':deadline', $data->deadline);

        if($stmt->execute()){
            echo json_encode(["message" => "Project created."]);
        }
    }
}
