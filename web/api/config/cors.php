<?php
// =========================================================================
// OneDev Track - CORS & Security Headers (Production Hardened)
// =========================================================================

// السماح فقط لدومين موقعك الرسمي لمنع الاستدعاءات الخبيثة من مواقع خارجية
$allowed_origins = [
    "https://onedev.ovh",
    "http://localhost"
];

$origin = isset($_SERVER['HTTP_ORIGIN']) ? $_SERVER['HTTP_ORIGIN'] : '';

if (in_array($origin, $allowed_origins)) {
    header("Access-Control-Allow-Origin: " . $origin);
} else {
    // في بيئة الإنتاج: تقييد الأصل بدومينك الرئيسي
    header("Access-Control-Allow-Origin: https://onedev.ovh");
}

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// التعامل السريع مع طلبات التمهيد Preflight (OPTIONS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
