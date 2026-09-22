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

        try {
            // 1. جلب وحذف كافة الملفات الفيزيائية المرفقة من السيرفر
            $att_stmt = $db->prepare("SELECT file_path FROM project_attachments WHERE project_id = :project_id");
            $att_stmt->bindParam(':project_id', $projectId);
            $att_stmt->execute();
            $attachments = $att_stmt->fetchAll(PDO::FETCH_ASSOC);

            foreach ($attachments as $att) {
                $filePath = __DIR__ . '/../../' . $att['file_path'];
                if (file_exists($filePath)) {
                    @unlink($filePath);
                }
            }

            // 2. مسح مجلدات المرفقات الخاصة بالمشروع (سواء كانت في rejections أو accepted)
            $rejDir = __DIR__ . '/../../uploads/rejections/project_' . $projectId;
            $accDir = __DIR__ . '/../../uploads/accepted/project_' . $projectId;

            foreach ([$rejDir, $accDir] as $pDir) {
                if (is_dir($pDir)) {
                    $files = glob($pDir . '/*');
                    foreach ($files as $f) {
                        if (is_file($f)) @unlink($f);
                    }
                    @rmdir($pDir);
                }
            }

            // 3. حذف كافة سجلات المرفقات من الداتا بيز
            $del_att_stmt = $db->prepare("DELETE FROM project_attachments WHERE project_id = :project_id");
            $del_att_stmt->bindParam(':project_id', $projectId);
            $del_att_stmt->execute();

            // 4. حذف كافة سجلات المراجعات والملاحظات من الداتا بيز
            $del_rev_stmt = $db->prepare("DELETE FROM project_revisions WHERE project_id = :project_id");
            $del_rev_stmt->bindParam(':project_id', $projectId);
            $del_rev_stmt->execute();

            // 5. حذف كافة مهام وشجرة مشروع الحريف من جدول tasks
            $del_task_stmt = $db->prepare("DELETE FROM tasks WHERE project_id = :project_id");
            $del_task_stmt->bindParam(':project_id', $projectId);
            $del_task_stmt->execute();

            // 6. حذف سجل المشروع الرئيسي نهائياً
            $query = "DELETE FROM projects WHERE id = :id";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':id', $projectId);

            if ($stmt->execute()) {
                echo json_encode(["message" => "Project and all associated files, tasks, revisions, and attachments deleted successfully."]);
            } else {
                http_response_code(500);
                echo json_encode(["message" => "Unable to delete project."]);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(["message" => "Error: " . $e->getMessage()]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["message" => "Incomplete data."]);
    }
}
