<?php
include_once '../config/cors.php';
include_once '../config/db.php';
include_once '../auth/verify.php';

$database = new Database();
$db = $database->getConnection();
$user = verifyToken($db, 'admin');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"));

    if(!empty($data->project_id) && !empty($data->title) && !empty($data->client_id) && !empty($data->duration_days)) {

        $q1 = "SELECT start_date FROM projects WHERE id = :id";
        $s1 = $db->prepare($q1);
        $s1->bindParam(':id', $data->project_id);
        $s1->execute();
        $proj = $s1->fetch(PDO::FETCH_ASSOC);

        if ($proj) {
            $start_date = $proj['start_date'];
            $deadline = date('Y-m-d', strtotime($start_date . ' + ' . $data->duration_days . ' days'));

            $query = "UPDATE projects SET title = :title, client_id = :client_id, description = :description, duration_days = :duration_days, deadline = :deadline WHERE id = :id";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':title', $data->title);
            $stmt->bindParam(':client_id', $data->client_id);
            $desc = isset($data->description) ? $data->description : '';
            $stmt->bindParam(':description', $desc);
            $stmt->bindParam(':duration_days', $data->duration_days);
            $stmt->bindParam(':deadline', $deadline);
            $stmt->bindParam(':id', $data->project_id);

            if($stmt->execute()){
                echo json_encode(["message" => "Project updated successfully."]);
            } else {
                http_response_code(500);
                echo json_encode(["message" => "Unable to update project."]);
            }
        } else {
            http_response_code(404);
            echo json_encode(["message" => "Project not found."]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["message" => "Incomplete data."]);
    }
}