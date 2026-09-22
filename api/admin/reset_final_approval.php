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

        // 1. جلب وحذف كافة الملفات المرفقة الفيزيائية من القرص بالسيرفر
        $att_stmt = $db->prepare("SELECT file_path FROM project_attachments WHERE project_id = :project_id");
        $att_stmt->bindParam(':project_id', $projectId);
        $att_stmt->execute();
        $attachments = $att_stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($attachments as $att) {
            $filePath = __DIR__ . '/../../track/' . $att['file_path'];
            if (file_exists($filePath)) {
                @unlink($filePath);
            }
        }

        // 2. حذف سجلات المرفقات من قاعدة البيانات
        $del_att_stmt = $db->prepare("DELETE FROM project_attachments WHERE project_id = :project_id");
        $del_att_stmt->bindParam(':project_id', $projectId);
        $del_att_stmt->execute();

        // 3. حذف سجلات المراجعات والملاحظات من جدول project_revisions كلياً
        $del_rev_stmt = $db->prepare("DELETE FROM project_revisions WHERE project_id = :project_id");
        $del_rev_stmt->bindParam(':project_id', $projectId);
        $del_rev_stmt->execute();

        // 4. إعادة تعيين حالة الاستلام النهائي ومسح الملاحظات وتاريخ المصادقة
        $query = "UPDATE projects SET final_approval_status = 'pending', final_approval_notes = NULL, final_approval_date = NULL WHERE id = :id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':id', $projectId);

        if ($stmt->execute()) {
            echo json_encode(["message" => "Final approval, attachments and revisions reset successfully."]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Failed to reset final approval."]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["message" => "Incomplete data."]);
    }
}