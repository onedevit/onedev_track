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
        // إعادة تعيين حالة الاستلام النهائي ومسح الملاحظات وتاريخ المصادقة
        $query = "UPDATE projects SET final_approval_status = 'pending', final_approval_notes = NULL, final_approval_date = NULL WHERE id = :id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':id', $data->project_id);

        if ($stmt->execute()) {
            echo json_encode(["message" => "Final approval reset successfully."]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Failed to reset final approval."]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["message" => "Incomplete data."]);
    }
}