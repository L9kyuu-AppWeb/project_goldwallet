<?php
require_once '../db_config.php';

$data = getJsonInput();

$wallet_id = $data['wallet_id'];
$amount = (float)$data['amount'];
$type = $data['type']; // income, expense, transfer
$category_id = $data['category_id'] ?? null;
$note = $data['note'] ?? '';
$date = $data['date']; // ISO format

$conn->begin_transaction();

try {
    $stmt = $conn->prepare("INSERT INTO transactions (wallet_id, category_id, amount, type, note, date) VALUES (?, ?, ?, ?, ?, ?)");
    $stmt->bind_param("iidsss", $wallet_id, $category_id, $amount, $type, $note, $date);
    $stmt->execute();
    $tx_id = $conn->insert_id;

    if ($type === 'income') {
        $conn->query("UPDATE wallets SET balance = balance + $amount WHERE id = $wallet_id");
    } else {
        $conn->query("UPDATE wallets SET balance = balance - $amount WHERE id = $wallet_id");
    }

    $conn->commit();
    echo json_encode(["status" => "success", "id" => $tx_id]);
} catch (Exception $e) {
    $conn->rollback();
    sendError($e->getMessage());
}
?>
