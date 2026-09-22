<?php
include_once '../config/cors.php';
include_once '../config/db.php';
include_once '../auth/verify.php';

$database = new Database();
$db = $database->getConnection();
$user = verifyToken($db, 'admin');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"));
    if(!empty($data->client_id) && !empty($data->username)) {
        $fullName = isset($data->full_name) ? $data->full_name : '';
        $country = isset($data->country) ? $data->country : '';
        $state = isset($data->state) ? $data->state : '';
        $city = isset($data->city) ? $data->city : '';
        $companyName = isset($data->company_name) ? $data->company_name : '';
        $prefLang = isset($data->preferred_language) && in_array($data->preferred_language, ['ar', 'en', 'fr']) ? $data->preferred_language : 'ar';

        if(!empty($data->password)) {
            $pwd = password_hash($data->password, PASSWORD_BCRYPT);
            $stmt = $db->prepare("UPDATE users SET username = :username, password = :password, full_name = :full_name, country = :country, state = :state, city = :city, company_name = :company_name, preferred_language = :preferred_language WHERE id = :id AND role = 'client'");
            $stmt->bindParam(':password', $pwd);
        } else {
            $stmt = $db->prepare("UPDATE users SET username = :username, full_name = :full_name, country = :country, state = :state, city = :city, company_name = :company_name, preferred_language = :preferred_language WHERE id = :id AND role = 'client'");
        }
        $stmt->bindParam(':username', $data->username);
        $stmt->bindParam(':full_name', $fullName);
        $stmt->bindParam(':country', $country);
        $stmt->bindParam(':state', $state);
        $stmt->bindParam(':city', $city);
        $stmt->bindParam(':company_name', $companyName);
        $stmt->bindParam(':preferred_language', $prefLang);
        $stmt->bindParam(':id', $data->client_id);

        if($stmt->execute()){
            echo json_encode(["message" => "Client updated successfully."]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Failed to update client."]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["message" => "Incomplete data."]);
    }
}
