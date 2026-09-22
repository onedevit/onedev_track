<?php
include_once '../config/cors.php';
include_once '../config/db.php';
include_once '../auth/verify.php';

$database = new Database();
$db = $database->getConnection();
$user = verifyToken($db, 'admin');

// دالة لإعادة تغيير حالة المهمة الأب إلى pending عند إضافة مهمة فرعية جديدة
function resetParentStatusToPending($db, $taskId) {
    $stmt = $db->prepare("SELECT parent_id, status FROM tasks WHERE id = :id");
    $stmt->bindParam(':id', $taskId);
    $stmt->execute();
    $task = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($task) {
        if ($task['status'] === 'completed') {
            $updateStmt = $db->prepare("UPDATE tasks SET status = 'pending', completed_at = NULL WHERE id = :id");
            $updateStmt->bindParam(':id', $taskId);
            $updateStmt->execute();
        }
        if (!empty($task['parent_id'])) {
            resetParentStatusToPending($db, $task['parent_id']);
        }
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['project_id'])) {
    $query = "SELECT * FROM tasks WHERE project_id = :project_id ORDER BY created_at ASC";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':project_id', $_GET['project_id']);
    $stmt->execute();
    echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"));
    if(!empty($data->project_id) && !empty($data->title)) {
        $parent_id = !empty($data->parent_id) ? $data->parent_id : null;

        $query = "INSERT INTO tasks (project_id, parent_id, title, description) VALUES (:project_id, :parent_id, :title, :description)";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':project_id', $data->project_id);
        $stmt->bindParam(':parent_id', $parent_id);
        $stmt->bindParam(':title', $data->title);
        $desc = isset($data->description) ? $data->description : '';
        $stmt->bindParam(':description', $desc);

        if($stmt->execute()){
            // إذا تم إضافة مهمة فرعية جديدة لمهمة كانت مكتملة، نعيد حالتها وحالة آبائها إلى غير مكتملة
            if ($parent_id) {
                resetParentStatusToPending($db, $parent_id);
            }
            echo json_encode(["message" => "Task created."]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Failed to create task."]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["message" => "Incomplete data."]);
    }
}