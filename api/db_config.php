<?php
// api/db_config.php

$host = 'localhost';
$user = 'root'; // Sesuaikan saat deploy
$pass = '';     // Sesuaikan saat deploy
$db   = 'gold_wallet';

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    header('Content-Type: application/json');
    die(json_encode(["error" => "Database Connection failed: " . $conn->connect_error]));
}

header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS, DELETE, PUT");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}


// Helper to get JSON input
function getJsonInput() {
    return json_decode(file_get_contents('php://input'), true);
}

// Helper to handle error
function sendError($message) {
    echo json_encode(["status" => "error", "message" => $message]);
    exit;
}
?>
