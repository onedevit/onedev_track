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
    $projects = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($projects as &$project) {
        $att_query = "SELECT * FROM project_attachments WHERE project_id = :project_id ORDER BY created_at ASC";
        $att_stmt = $db->prepare($att_query);
        $att_stmt->bindParam(':project_id', $project['id']);
        $att_stmt->execute();
        $project['attachments'] = $att_stmt->fetchAll(PDO::FETCH_ASSOC);

        $rev_query = "SELECT * FROM project_revisions WHERE project_id = :project_id ORDER BY revision_number ASC";
        $rev_stmt = $db->prepare($rev_query);
        $rev_stmt->bindParam(':project_id', $project['id']);
        $rev_stmt->execute();
        $project['revisions'] = $rev_stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    echo json_encode($projects);
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
