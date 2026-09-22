<?php
include_once '../config/cors.php';
include_once '../config/db.php';
include_once '../auth/verify.php';

$database = new Database();
$db = $database->getConnection();
$user = verifyToken($db, 'admin');

// دالة عودية (Recursive) للتحقق وإنجاز المهام الأب تلقائياً
function checkAndUpdateParentStatus($db, $taskId) {
    // 1. جلب parent_id للمهمة الحالية
    $stmt = $db->prepare("SELECT parent_id FROM tasks WHERE id = :id");
    $stmt->bindParam(':id', $taskId);
    $stmt->execute();
    $task = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($task && !empty($task['parent_id'])) {
        $parentId = $task['parent_id'];

        // 2. التحقق مما إذا كانت جميع المهام الأخوة (التي لها نفس parent_id) منجزة
        $checkStmt = $db->prepare("SELECT COUNT(*) as pending_count FROM tasks WHERE parent_id = :parent_id AND status != 'completed'");
        $checkStmt->bindParam(':parent_id', $parentId);
        $checkStmt->execute();
        $result = $checkStmt->fetch(PDO::FETCH_ASSOC);

        // إذا كان عدد المهام المعلقة = 0، فهذا يعني أن كافة المهام الفرعية اكتملت!
        if ($result['pending_count'] == 0) {
            $autoNote = "تم إنجاز هذه المرحلة تلقائياً لاكتمال جميع مهامها الفرعية.";
            $updateStmt = $db->prepare("UPDATE tasks SET status = 'completed', notes = :notes, completed_at = CURRENT_TIMESTAMP WHERE id = :id");
            $updateStmt->bindParam(':notes', $autoNote);
            $updateStmt->bindParam(':id', $parentId);
            $updateStmt->execute();

            // 3. التحقق بشكل عودي للمهمة الأب الأعلى (Level 0)
            checkAndUpdateParentStatus($db, $parentId);
        }
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"));
    if(!empty($data->task_id)) {
        $notes = isset($data->notes) ? $data->notes : '';
        $query = "UPDATE tasks SET status = 'completed', notes = :notes, completed_at = CURRENT_TIMESTAMP WHERE id = :id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':notes', $notes);
        $stmt->bindParam(':id', $data->task_id);

        if($stmt->execute()){
            // تشغيل دالة التحديث التلقائي للمهام الأب
            checkAndUpdateParentStatus($db, $data->task_id);
            echo json_encode(["message" => "Task validated successfully."]);
        } else {
            http_response_code(503);
            echo json_encode(["message" => "Unable to validate task."]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["message" => "Task ID is required."]);
    }
}