<?php
require_once '../db_config.php';

$data = getJsonInput();
$name = $data['name'] ?? '';
$type = $data['type'] ?? 'expense';
$icon = $data['icon'] ?? null;

$stmt = $conn->prepare("INSERT INTO categories (name, type, icon) VALUES (?, ?, ?)");
$stmt->bind_param("sss", $name, $type, $icon);

if ($stmt->execute()) {
    echo json_encode(["status" => "success", "id" => $conn->insert_id]);
} else {
    sendError($stmt->error);
}
?>
