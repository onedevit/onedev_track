<?php
// =========================================================================
// OneDev Track - Database Connection Configuration (Production Hardened)
// =========================================================================

class Database {
    // يفضل استخدام متغيرات البيئة بدلاً من كتابتها نصياً إذا أمكن
    private $host = "localhost";
    private $db_name = "onedev_track";
    private $username = "onedev_track"; // قم بتحديث اسم مستخدم قاعدة البيانات في السيرفر
    private $password = "CgK92dHap9SzFZm!@2026"; // قم بتحديث كلمة مرور قاعدة البيانات في السيرفر
    public $conn;

    public function getConnection() {
        $this->conn = null;
        try {
            // خيارات الأمان المتقدمة لمنع تسريب البيانات وإلغاء محاكاة SQL Injection
            $options = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false, // استخدام الاستعلامات المجهزة الحقيقية من المايسكيول
                PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci"
            ];

            $this->conn = new PDO(
                "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=utf8mb4",
                $this->username,
                $this->password,
                $options
            );
        } catch(PDOException $exception) {
            // [حماية قصوى]: تسجيل الخطأ التفصيلي في سجل السيرفر الخاص فقط وعدم إظهاره للعموم
            error_log("Database Connection Error: " . $exception->getMessage());

            // إرجاع رسالة خطأ عامة ومبهمة للزائر لمنع تسريب كلمة المرور أو اسم السيرفر
            http_response_code(503);
            echo json_encode(["message" => "Service temporarily unavailable. Please try again later."]);
            exit;
        }
        return $this->conn;
    }
}
