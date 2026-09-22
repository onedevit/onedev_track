<?php
include_once '../config/cors.php';
include_once '../config/db.php';
include_once '../auth/verify.php';

$database = new Database();
$db = $database->getConnection();
// التحقق من أن المستخدم هو عميل (Client)
$user = verifyToken($db, 'client');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $projectId = isset($_POST['project_id']) ? intval($_POST['project_id']) : 0;

    if ($projectId <= 0) {
        http_response_code(400);
        echo json_encode(["message" => "Invalid project ID."]);
        exit();
    }

    // التحقق من أن المشروع يتبع لهذا العميل تحديداً
    $check = "SELECT id FROM projects WHERE id = :id AND client_id = :client_id";
    $check_stmt = $db->prepare($check);
    $check_stmt->bindParam(':id', $projectId);
    $check_stmt->bindParam(':client_id', $user['id']);
    $check_stmt->execute();

    if ($check_stmt->rowCount() === 0) {
        http_response_code(403);
        echo json_encode(["message" => "Unauthorized project access."]);
        exit();
    }

    // التحقق من أن عدد المرفقات الحالية لهذا المشروع لم يتجاوز 5 مرفقات
    $count_stmt = $db->prepare("SELECT COUNT(*) as count FROM project_attachments WHERE project_id = :project_id");
    $count_stmt->bindParam(':project_id', $projectId);
    $count_stmt->execute();
    $current_count = $count_stmt->fetch(PDO::FETCH_ASSOC)['count'];

    if ($current_count >= 5) {
        http_response_code(400);
        echo json_encode(["message" => "Maximum 5 attachments allowed per project."]);
        exit();
    }

    if (!isset($_FILES['file'])) {
        http_response_code(400);
        echo json_encode(["message" => "No file received by server."]);
        exit();
    }

    $file = $_FILES['file'];

    // التحقق من أخطاء الرفع الداخلية في سيرفر الـ PHP
    if ($file['error'] !== UPLOAD_ERR_OK) {
        $errCode = $file['error'];
        $errMsg = "PHP upload error code: " . $errCode;
        if ($errCode === UPLOAD_ERR_INI_SIZE || $errCode === UPLOAD_ERR_FORM_SIZE) {
            $errMsg = "File size exceeds PHP server upload limit (upload_max_filesize).";
        } elseif ($errCode === UPLOAD_ERR_CANT_WRITE) {
            $errMsg = "Server write permission error on temp folder.";
        }
        http_response_code(400);
        echo json_encode(["message" => $errMsg]);
        exit();
    }

    $maxSize = 30 * 1024 * 1024; // 30 Megabytes

    if ($file['size'] > $maxSize) {
        http_response_code(400);
        echo json_encode(["message" => "File size exceeds 30MB limit."]);
        exit();
    }

    $allowedExts = ['pdf', 'jpg', 'jpeg', 'png', 'webp'];
    $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));

    if (!in_array($ext, $allowedExts)) {
        http_response_code(400);
        echo json_encode(["message" => "File type not allowed. Allowed: PDF, JPG, PNG, WEBP."]);
        exit();
    }

    // إنشاء مجلد التخزين المخصص داخل مسار الـ Track مع التأكد من صلاحيات الكتابة
    $targetDir = __DIR__ . '/../../track/uploads/rejections/';
    if (!is_dir($targetDir)) {
        @mkdir($targetDir, 0777, true);
    }

    $uniqueName = 'att_' . $projectId . '_' . uniqid() . '.' . $ext;
    $targetFilePath = $targetDir . $uniqueName;

    if (move_uploaded_file($file['tmp_name'], $targetFilePath)) {
        $publicUrl = 'uploads/rejections/' . $uniqueName;
        $originalName = basename($file['name']);
        $fileSize = $file['size'];

        // حفظ المرفق في قاعدة البيانات
        $insert_stmt = $db->prepare("INSERT INTO project_attachments (project_id, file_name, file_path, file_type, file_size) VALUES (:project_id, :file_name, :file_path, :file_type, :file_size)");
        $insert_stmt->bindParam(':project_id', $projectId);
        $insert_stmt->bindParam(':file_name', $originalName);
        $insert_stmt->bindParam(':file_path', $publicUrl);
        $insert_stmt->bindParam(':file_type', $ext);
        $insert_stmt->bindParam(':file_size', $fileSize);

        if ($insert_stmt->execute()) {
            $attachmentId = $db->lastInsertId();
            echo json_encode([
                "message" => "Attachment uploaded successfully.",
                "attachment" => [
                    "id" => $attachmentId,
                    "project_id" => $projectId,
                    "file_name" => $originalName,
                    "file_path" => $publicUrl,
                    "file_type" => $ext,
                    "file_size" => $fileSize
                ]
            ]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Database insert error."]);
        }
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Failed to save file on server. Please check folder write permissions on /track/uploads/rejections."]);
    }
}
