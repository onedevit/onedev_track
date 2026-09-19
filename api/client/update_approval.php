<?php
include_once '../config/cors.php';
include_once '../config/db.php';
include_once '../auth/verify.php';

$database = new Database();
$db = $database->getConnection();
// التحقق من أن المستخدم هو عميل (Client)
$user = verifyToken($db, 'client');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"));

    if(!empty($data->project_id) && !empty($data->status)) {
        $status = $data->status; // 'approved' or 'rejected'
        $reason = isset($data->reason) ? $data->reason : null;

        // التحقق من أن المشروع يتبع لهذا العميل تحديداً
        $check = "SELECT id FROM projects WHERE id = :id AND client_id = :client_id";
        $check_stmt = $db->prepare($check);
        $check_stmt->bindParam(':id', $data->project_id);
        $check_stmt->bindParam(':client_id', $user['id']);
        $check_stmt->execute();

        if($check_stmt->rowCount() > 0) {
            $query = "UPDATE projects SET client_approval_status = :status, client_rejection_reason = :reason WHERE id = :id";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':status', $status);
            $stmt->bindParam(':reason', $reason);
            $stmt->bindParam(':id', $data->project_id);

            if($stmt->execute()){
                echo json_encode(["message" => "Approval status updated."]);
            } else {
                http_response_code(500);
                echo json_encode(["message" => "Failed to update."]);
            }
        } else {
            http_response_code(403);
            echo json_encode(["message" => "Unauthorized."]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["message" => "Incomplete data."]);
    }
}