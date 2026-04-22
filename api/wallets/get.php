<?php
require_once '../db_config.php';

$id = $_GET['id'] ?? null;
if (!$id) sendError("ID is required");

$stmt = $conn->prepare("SELECT * FROM wallets WHERE id = ?");
$stmt->bind_param("i", $id);
$stmt->execute();
$result = $stmt->get_result();
$wallet = $result->fetch_assoc();

if ($wallet) {
    $wallet['id'] = (int)$wallet['id'];
    $wallet['balance'] = (float)$wallet['balance'];
    $wallet['is_main'] = (int)$wallet['is_main'];
    echo json_encode($wallet);
} else {
    echo json_encode(null);
}
?>
