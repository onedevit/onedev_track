<?php
class Database {
    private $host = "localhost";
    private $db_name = "onedev_track";
    private $username = "onedev_track"; // قم بتعديلها عند الرفع للسيرفر
    private $password = "CgK92dHap9SzFZm!@2026";     // قم بتعديلها عند الرفع للسيرفر
    public $conn;

    public function getConnection() {
        $this->conn = null;
        try {
            $this->conn = new PDO("mysql:host=" . $this->host . ";dbname=" . $this->db_name, $this->username, $this->password);
            $this->conn->exec("set names utf8");
        } catch(PDOException $exception) {
            echo json_encode(["error" => "Database connection error: " . $exception->getMessage()]);
            exit;
        }
        return $this->conn;
    }
}
