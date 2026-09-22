<?php
include_once '../config/cors.php';
include_once '../config/db.php';
include_once '../auth/verify.php';

$database = new Database();
$db = $database->getConnection();
$user = verifyToken($db, 'admin');

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // جلب كافة الحرفاء مع بياناتهم الكاملة وعدد المشاريع
    $query = "SELECT u.id, u.username, u.full_name, u.country, u.state, u.city, u.company_name, u.preferred_language,
              (SELECT COUNT(*) FROM projects WHERE client_id = u.id) as projects_count
              FROM users u
              WHERE u.role = 'client'
              ORDER BY u.id DESC";
    $stmt = $db->prepare($query);
    $stmt->execute();
    echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"));
    if(!empty($data->username) && !empty($data->password)) {
        // التحقق من عدم تكرار اسم المستخدم
        $c_stmt = $db->prepare("SELECT id FROM users WHERE username = :username LIMIT 1");
        $c_stmt->bindParam(':username', $data->username);
        $c_stmt->execute();
        if($c_stmt->rowCount() > 0) {
            http_response_code(400);
            echo json_encode(["message" => "اسم المستخدم موجود مسبقاً."]);
            exit;
        }

        $pwd = password_hash($data->password, PASSWORD_BCRYPT);
        $query = "INSERT INTO users (username, password, full_name, country, state, city, company_name, preferred_language, role)
                  VALUES (:username, :password, :full_name, :country, :state, :city, :company_name, :preferred_language, 'client')";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':username', $data->username);
        $stmt->bindParam(':password', $pwd);

        $fullName = isset($data->full_name) ? $data->full_name : '';
        $country = isset($data->country) ? $data->country : '';
        $state = isset($data->state) ? $data->state : '';
        $city = isset($data->city) ? $data->city : '';
        $companyName = isset($data->company_name) ? $data->company_name : '';
        $prefLang = isset($data->preferred_language) && in_array($data->preferred_language, ['ar', 'en', 'fr']) ? $data->preferred_language : 'ar';

        $stmt->bindParam(':full_name', $fullName);
        $stmt->bindParam(':country', $country);
        $stmt->bindParam(':state', $state);
        $stmt->bindParam(':city', $city);
        $stmt->bindParam(':company_name', $companyName);
        $stmt->bindParam(':preferred_language', $prefLang);

        if($stmt->execute()){
            echo json_encode(["message" => "Client created successfully."]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Failed to create client."]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["message" => "Incomplete data."]);
    }
}
