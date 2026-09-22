<?php
include_once '../config/cors.php';
include_once '../config/db.php';
include_once '../auth/verify.php';

$database = new Database();
$db = $database->getConnection();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // جلب كافة إعدادات النظام الحالية
    $query = "SELECT setting_key, setting_value FROM system_settings";
    $stmt = $db->prepare($query);
    $stmt->execute();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $settings = [
        "max_attachments_count" => "5",
        "max_file_size_mb" => "30",
        "auto_delete_attachments_days" => "30",
        "cron_secret_token" => "ONEDEV_CLEANUP_CRON_2026_SECURE"
    ];

    foreach ($rows as $row) {
        $settings[$row['setting_key']] = $row['setting_value'];
    }

    echo json_encode($settings);
    exit();
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // التحقق من أن المستخدم هو أدمن لتعديل الإعدادات
    $user = verifyToken($db, 'admin');
    $data = json_decode(file_get_contents("php://input"), true);

    if (!empty($data) && is_array($data)) {
        foreach ($data as $key => $val) {
            $query = "INSERT INTO system_settings (setting_key, setting_value) VALUES (:key, :val)
                      ON DUPLICATE KEY UPDATE setting_value = :val2";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':key', $key);
            $stmt->bindParam(':val', $val);
            $stmt->bindParam(':val2', $val);
            $stmt->execute();
        }

        echo json_encode(["message" => "Settings updated successfully."]);
    } else {
        http_response_code(400);
        echo json_encode(["message" => "Invalid data."]);
    }
}
