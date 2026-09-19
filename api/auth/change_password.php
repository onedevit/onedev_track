<?php
include_once '../config/cors.php';
include_once '../config/db.php';
include_once '../auth/verify.php';

$database = new Database();
$db = $database->getConnection();

// التحقق من صلاحية التوكن للمستخدم المسجل حالياً (سواء أدمن أو حريف)
$user = verifyToken($db);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"));

    if (!empty($data->old_password) && !empty($data->new_password)) {
        // جلب كلمة المرور المشفرة الحالية للمستخدم
        $stmt = $db->prepare("SELECT password FROM users WHERE id = :id LIMIT 1");
        $stmt->bindParam(':id', $user['id']);
        $stmt->execute();
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($row && password_verify($data->old_password, $row['password'])) {
            $newHash = password_hash($data->new_password, PASSWORD_BCRYPT);
            $u_stmt = $db->prepare("UPDATE users SET password = :pwd WHERE id = :id");
            $u_stmt->bindParam(':pwd', $newHash);
            $u_stmt->bindParam(':id', $user['id']);

            if ($u_stmt->execute()) {
                echo json_encode(["message" => "Password updated successfully."]);
            } else {
                http_response_code(500);
                echo json_encode(["message" => "Failed to update password."]);
            }
        } else {
            http_response_code(400);
            echo json_encode(["message" => "كلمة المرور القديمة غير صحيحة."]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["message" => "Incomplete data."]);
    }
}
