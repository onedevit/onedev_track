<?php
include_once '../config/cors.php';
include_once '../config/db.php';
include_once '../auth/verify.php';

$database = new Database();
$db = $database->getConnection();
$user = verifyToken($db, 'client');

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // جلب كافة المشاريع المرتبطة بهذا العميل مع الإحصائيات الدقيقة للمهام
    $query = "SELECT p.*,
              (SELECT COUNT(*) FROM tasks WHERE project_id = p.id) as total_tasks,
              (SELECT COUNT(*) FROM tasks WHERE project_id = p.id AND status = 'completed') as completed_tasks
              FROM projects p
              WHERE p.client_id = :client_id
              ORDER BY p.created_at DESC";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':client_id', $user['id']);
    $stmt->execute();

    $projects = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // جلب المهام والمرفقات وسجل المراجعات التاريخية الخاصة بكل مشروع
    foreach ($projects as &$project) {
        $t_query = "SELECT * FROM tasks WHERE project_id = :project_id ORDER BY created_at ASC";
        $t_stmt = $db->prepare($t_query);
        $t_stmt->bindParam(':project_id', $project['id']);
        $t_stmt->execute();
        $project['tasks'] = $t_stmt->fetchAll(PDO::FETCH_ASSOC);

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
}