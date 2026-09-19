<?php
include_once '../config/cors.php';
include_once '../config/db.php';
include_once '../auth/verify.php';

$database = new Database();
$db = $database->getConnection();
$user = verifyToken($db, 'client');

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // جلب كافة المشاريع المرتبطة بهذا العميل (حتى لو كانت متعددة)
    $query = "SELECT * FROM projects WHERE client_id = :client_id ORDER BY created_at DESC";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':client_id', $user['id']);
    $stmt->execute();

    $projects = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // جلب المهام الخاصة بكل مشروع
    foreach ($projects as &$project) {
        $t_query = "SELECT * FROM tasks WHERE project_id = :project_id ORDER BY created_at ASC";
        $t_stmt = $db->prepare($t_query);
        $t_stmt->bindParam(':project_id', $project['id']);
        $t_stmt->execute();
        $project['tasks'] = $t_stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    echo json_encode($projects);
}