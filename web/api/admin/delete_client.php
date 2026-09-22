<?php
include_once '../config/cors.php';
include_once '../config/db.php';
include_once '../auth/verify.php';

$database = new Database();
$db = $database->getConnection();
$user = verifyToken($db, 'admin');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"));
    if (!empty($data->client_id)) {
        $clientId = intval($data->client_id);

        try {
            // 1. جلب كافة مشاريع العميل لحذف مرفقاتها وملفاتها من السيرفر كلياً
            $p_stmt = $db->prepare("SELECT id FROM projects WHERE client_id = :client_id");
            $p_stmt->bindParam(':client_id', $clientId);
            $p_stmt->execute();
            $projects = $p_stmt->fetchAll(PDO::FETCH_ASSOC);

            foreach ($projects as $proj) {
                $projectId = intval($proj['id']);

                // جلب وحذف ملفات المرفقات الفيزيائية
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

                // مسح مجلدات المشروع (rejections و accepted)
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

                // حذف سجلات الداتا بيز التابعة للمشروع
                $db->prepare("DELETE FROM project_attachments WHERE project_id = $projectId")->execute();
                $db->prepare("DELETE FROM project_revisions WHERE project_id = $projectId")->execute();
                $db->prepare("DELETE FROM tasks WHERE project_id = $projectId")->execute();
                $db->prepare("DELETE FROM projects WHERE id = $projectId")->execute();
            }

            // 2. حذف حساب الحريف من جدول المستخدمين
            $stmt = $db->prepare("DELETE FROM users WHERE id = :id AND role = 'client'");
            $stmt->bindParam(':id', $clientId);

            if ($stmt->execute()) {
                echo json_encode(["message" => "Client and all associated projects and files deleted successfully."]);
            } else {
                http_response_code(500);
                echo json_encode(["message" => "Failed to delete client."]);
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
