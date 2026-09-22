<?php
include_once '../config/cors.php';
include_once '../config/db.php';
include_once '../auth/verify.php';

$database = new Database();
$db = $database->getConnection();
// التحقق من أن المستخدم هو مدير النظام (Admin)
$user = verifyToken($db, 'admin');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"));

    if (!empty($data->project_id)) {
        $projectId = intval($data->project_id);

        // 1. تعليم جميع الملاحظات المعلقة السابقة بـ "تمت المعالجة من الإدارة"
        $upd_rev = $db->prepare("UPDATE project_revisions SET status = 'resolved', resolved_at = NOW() WHERE project_id = :project_id AND status = 'pending'");
        $upd_rev->bindParam(':project_id', $projectId);
        $upd_rev->execute();

        // 2. إعادة حالة المصادقة النهائية إلى pending ليعود للموافقة لدى الحريف مع حفظ سجل الملاحظات والمرفقات
        $query = "UPDATE projects SET final_approval_status = 'pending' WHERE id = :id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':id', $projectId);

        if ($stmt->execute()) {
            echo json_encode(["message" => "Revision resolved and project resubmitted for final approval."]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Failed to resubmit project."]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["message" => "Incomplete data."]);
    }
}