<?php
require_once '../db_config.php';

$data = getJsonInput();
$id = $data['id'] ?? null;

if (!$id) sendError("ID is required");

$stmt = $conn->prepare("DELETE FROM wallets WHERE id = ?");
$stmt->bind_param("i", $id);

if ($stmt->execute()) {
    echo json_encode(["status" => "success"]);
} else {
    sendError($stmt->error);
}
?>
