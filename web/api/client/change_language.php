<?php
include_once '../config/cors.php';
include_once '../config/db.php';
include_once '../auth/verify.php';

$database = new Database();
$db = $database->getConnection();
$user = verifyToken($db); // يمكن التغيير من العميل أو الأدمن

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"));

    if (!empty($data->language)) {
        $lang = strtolower(trim($data->language));
        if (in_array($lang, ['ar', 'en', 'fr'])) {
            $stmt = $db->prepare("UPDATE users SET preferred_language = :lang WHERE id = :id");
            $stmt->bindParam(':lang', $lang);
            $stmt->bindParam(':id', $user['id']);

            if ($stmt->execute()) {
                echo json_encode(["message" => "Preferred language updated successfully.", "preferred_language" => $lang]);
            } else {
                http_response_code(500);
                echo json_encode(["message" => "Failed to update language."]);
            }
        } else {
            http_response_code(400);
            echo json_encode(["message" => "Invalid language code."]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["message" => "Missing language parameter."]);
    }
}
