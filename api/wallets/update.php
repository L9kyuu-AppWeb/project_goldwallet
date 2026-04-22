<?php
require_once '../db_config.php';

$data = getJsonInput();
$id = $data['id'] ?? null;

if (!$id) sendError("ID is required");

$name = $data['name'];
$type = $data['type'];
$balance = $data['balance'];

$stmt = $conn->prepare("UPDATE wallets SET name = ?, type = ?, balance = ? WHERE id = ?");
$stmt->bind_param("ssdi", $name, $type, $balance, $id);

if ($stmt->execute()) {
    echo json_encode(["status" => "success"]);
} else {
    sendError($stmt->error);
}
?>
