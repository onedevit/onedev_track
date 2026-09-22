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
        $projectId = intval($data->project_id);
        $status = $data->status; // 'approved' or 'rejected'
        $notes = isset($data->notes) ? trim($data->notes) : null;

        // التحقق من أن المشروع يتبع لهذا العميل تحديداً
        $check = "SELECT id FROM projects WHERE id = :id AND client_id = :client_id";
        $check_stmt = $db->prepare($check);
        $check_stmt->bindParam(':id', $projectId);
        $check_stmt->bindParam(':client_id', $user['id']);
        $check_stmt->execute();

        if($check_stmt->rowCount() > 0) {
            if ($status === 'rejected' && !empty($notes)) {
                // 1. حساب رقم المراجعة التراكمية القادمة (Revision Number)
                $rev_num_stmt = $db->prepare("SELECT COALESCE(MAX(revision_number), 0) + 1 as next_rev FROM project_revisions WHERE project_id = :project_id");
                $rev_num_stmt->bindParam(':project_id', $projectId);
                $rev_num_stmt->execute();
                $next_rev = $rev_num_stmt->fetch(PDO::FETCH_ASSOC)['next_rev'];

                // 2. أدراج الملاحظة الجديدة في سجل المراجعات
                $ins_rev = $db->prepare("INSERT INTO project_revisions (project_id, revision_number, client_notes, status) VALUES (:project_id, :revision_number, :client_notes, 'pending')");
                $ins_rev->bindParam(':project_id', $projectId);
                $ins_rev->bindParam(':revision_number', $next_rev);
                $ins_rev->bindParam(':client_notes', $notes);
                $ins_rev->execute();
                $revisionId = $db->lastInsertId();

                // 3. ربط المرفقات المعلقة بهذه المراجعة
                $upd_att = $db->prepare("UPDATE project_attachments SET revision_id = :revision_id WHERE project_id = :project_id AND revision_id IS NULL");
                $upd_att->bindParam(':revision_id', $revisionId);
                $upd_att->bindParam(':project_id', $projectId);
                $upd_att->execute();
            }

            // 4. تحديث حالة المشروع الرئيسية
            $query = "UPDATE projects SET final_approval_status = :status, final_approval_notes = :notes, final_approval_date = NOW() WHERE id = :id";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':status', $status);
            $stmt->bindParam(':notes', $notes);
            $stmt->bindParam(':id', $projectId);

            if($stmt->execute()){
                echo json_encode(["message" => "Final handover approval updated."]);
            } else {
                http_response_code(500);
                echo json_encode(["message" => "Failed to update final approval."]);
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