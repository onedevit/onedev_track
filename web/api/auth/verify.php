<?php
function verifyToken($db, $requiredRole = null) {
    $headers = apache_request_headers();
    $token = null;

    if (isset($headers['Authorization'])) {
        $token = str_replace('Bearer ', '', $headers['Authorization']);
    }

    if(!$token) {
        http_response_code(401);
        echo json_encode(["message" => "Access denied. Token missing."]);
        exit;
    }

    $query = "SELECT id, role FROM users WHERE token = :token LIMIT 1";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':token', $token);
    $stmt->execute();

    if($stmt->rowCount() > 0) {
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        if($requiredRole && $user['role'] !== $requiredRole) {
            http_response_code(403);
            echo json_encode(["message" => "Access denied. Insufficient privileges."]);
            exit;
        }
        return $user;
    } else {
        http_response_code(401);
        echo json_encode(["message" => "Access denied. Invalid token."]);
        exit;
    }
}
