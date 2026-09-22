<?php
include_once '../config/cors.php';
include_once '../config/db.php';
// We skip verifyToken for debugging to see the database error

$database = new Database();
$db = $database->getConnection();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"));

    // We will catch PDO exceptions directly
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    try {
        if(!empty($data->title) && !empty($data->client_username) && !empty($data->start_date) && !empty($data->duration_days) && !empty($data->deadline) && !empty($data->client_password)) {

            $client_query = "SELECT id FROM users WHERE username = :username LIMIT 1";
            $c_stmt = $db->prepare($client_query);
            $c_stmt->bindParam(':username', $data->client_username);
            $c_stmt->execute();

            if($c_stmt->rowCount() > 0) {
                $client = $c_stmt->fetch(PDO::FETCH_ASSOC);
                $client_id = $client['id'];
            } else {
                $pwd = password_hash($data->client_password, PASSWORD_BCRYPT);
                $i_stmt = $db->prepare("INSERT INTO users (username, password, role) VALUES (:username, :password, 'client')");
                $i_stmt->bindParam(':username', $data->client_username);
                $i_stmt->bindParam(':password', $pwd);
                $i_stmt->execute();
                $client_id = $db->lastInsertId();
            }

            $query = "INSERT INTO projects (client_id, title, start_date, duration_days, deadline) VALUES (:client_id, :title, :start_date, :duration_days, :deadline)";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':client_id', $client_id);
            $stmt->bindParam(':title', $data->title);
            $stmt->bindParam(':start_date', $data->start_date);
            $stmt->bindParam(':duration_days', $data->duration_days);
            $stmt->bindParam(':deadline', $data->deadline);

            if($stmt->execute()){
                echo json_encode(["message" => "Project created."]);
            }
        } else {
            echo json_encode(["error" => "Incomplete data", "received" => $data]);
        }
    } catch(PDOException $e) {
        echo json_encode(["error" => "SQL Error", "details" => $e->getMessage()]);
    }
}