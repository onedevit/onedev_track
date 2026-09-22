<?php
include_once '../config/cors.php';
include_once '../config/db.php';

$database = new Database();
$db = $database->getConnection();

// جلب توكن الأمان لـ Cron Job ديناميكياً من قاعدة البيانات
$CRON_SECRET_KEY = "ONEDEV_CLEANUP_CRON_2026_SECURE";
$token_stmt = $db->query("SELECT setting_value FROM system_settings WHERE setting_key = 'cron_secret_token'");
if ($token_stmt && $t_row = $token_stmt->fetch(PDO::FETCH_ASSOC)) {
    if (!empty($t_row['setting_value'])) {
        $CRON_SECRET_KEY = trim($t_row['setting_value']);
    }
}

$providedKey = isset($_GET['cron_key']) ? trim($_GET['cron_key']) : (isset($_POST['cron_key']) ? trim($_POST['cron_key']) : '');

// التحقق هل تم استدعاء السكربت مباشرة عبر HTTP من الخارج أم كـ include دالي داخلي
$isExternalRequest = (basename($_SERVER['SCRIPT_FILENAME']) === 'auto_cleanup_attachments.php');

if ($isExternalRequest) {
    if ($providedKey !== $CRON_SECRET_KEY) {
        http_response_code(403);
        echo json_encode([
            "status" => "error",
            "message" => "Unauthorized Cron Access. Invalid or missing secret cron_key."
        ]);
        exit();
    }
}

// 1. جلب مدة الاحتفاظ بالمرفقات بالأيام من جدول إعدادات النظام
$days_stmt = $db->query("SELECT setting_value FROM system_settings WHERE setting_key = 'auto_delete_attachments_days'");
$retention_days = 30; // القيمة الافتراضية 30 يوم

if ($days_stmt && $row = $days_stmt->fetch(PDO::FETCH_ASSOC)) {
    $retention_days = intval($row['setting_value']);
}

$deleted_files_count = 0;
$deleted_dirs_count = 0;

if ($retention_days > 0) {
    // 2. البحث فقط عن مرفقات المشاريع التي تمت المصادقة عليها وحصلت على موافقة التسليم النهائي (final_approval_status = 'approved') وتجاوزت مدة الحفظ
    $query = "SELECT pa.id, pa.file_path, pa.project_id
              FROM project_attachments pa
              JOIN projects p ON p.id = pa.project_id
              WHERE pa.file_deleted = 0
              AND p.final_approval_status = 'approved'
              AND pa.created_at <= DATE_SUB(NOW(), INTERVAL :days DAY)";

    $stmt = $db->prepare($query);
    $stmt->bindParam(':days', $retention_days, PDO::PARAM_INT);
    $stmt->execute();
    $old_attachments = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $affected_dirs = [];

    foreach ($old_attachments as $att) {
        $filePath = __DIR__ . '/../../track/' . $att['file_path'];
        $dirPath = dirname($filePath);

        // حذف الملف الفيزيائي من السيرفر
        if (file_exists($filePath)) {
            @unlink($filePath);
            $deleted_files_count++;
        }

        if (is_dir($dirPath)) {
            $affected_dirs[$dirPath] = true;
        }

        // تعليم السجل في قاعدة البيانات بأنه مؤرشف وتم حذف ملفه فيزيائياً
        $upd_stmt = $db->prepare("UPDATE project_attachments SET file_deleted = 1 WHERE id = :id");
        $upd_stmt->bindParam(':id', $att['id']);
        $upd_stmt->execute();
    }

    // تنظيف مجلدات المشاريع الفارغة إن وجدت
    foreach (array_keys($affected_dirs) as $dir) {
        if (is_dir($dir) && count(glob("$dir/*")) === 0) {
            if (@rmdir($dir)) {
                $deleted_dirs_count++;
            }
        }
    }
}

if ($isExternalRequest) {
    echo json_encode([
        "status" => "success",
        "timestamp" => date('Y-m-d H:i:s'),
        "retention_days" => $retention_days,
        "deleted_files_count" => $deleted_files_count,
        "deleted_dirs_count" => $deleted_dirs_count,
        "message" => "Cron cleanup executed successfully. Removed {$deleted_files_count} old file(s) and {$deleted_dirs_count} empty folder(s)."
    ]);
    exit();
}
