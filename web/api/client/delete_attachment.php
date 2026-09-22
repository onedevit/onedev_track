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

    if (!empty($data->attachment_id)) {
        $attachmentId = intval($data->attachment_id);

        // جلب المرفق والتحقق من ملكية المشروع
        $stmt = $db->prepare("SELECT a.*, p.client_id FROM project_attachments a JOIN projects p ON a.project_id = p.id WHERE a.id = :id AND p.client_id = :client_id");
        $stmt->bindParam(':id', $attachmentId);
        $stmt->bindParam(':client_id', $user['id']);
        $stmt->execute();

        if ($stmt->rowCount() > 0) {
            $att = $stmt->fetch(PDO::FETCH_ASSOC);
            $filePath = __DIR__ . '/../../track/' . $att['file_path'];

            if (file_exists($filePath)) {
                unlink($filePath);
            }

            $del_stmt = $db->prepare("DELETE FROM project_attachments WHERE id = :id");
            $del_stmt->bindParam(':id', $attachmentId);
            $del_stmt->execute();

            echo json_encode(["message" => "Attachment deleted successfully."]);
        } else {
            http_response_code(403);
            echo json_encode(["message" => "Unauthorized or attachment not found."]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["message" => "Incomplete data."]);
    }
}
