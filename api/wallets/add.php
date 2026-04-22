<?php
require_once '../db_config.php';

$data = getJsonInput();

$name = $data['name'] ?? '';
$type = $data['type'] ?? 'cash';
$balance = $data['balance'] ?? 0.0;
$is_main = ($data['is_main'] ?? false) ? 1 : 0;

$stmt = $conn->prepare("INSERT INTO wallets (name, type, balance, is_main) VALUES (?, ?, ?, ?)");
$stmt->bind_param("ssdi", $name, $type, $balance, $is_main);

if ($stmt->execute()) {
    echo json_encode(["status" => "success", "id" => $conn->insert_id]);
} else {
    sendError($stmt->error);
}
?>
