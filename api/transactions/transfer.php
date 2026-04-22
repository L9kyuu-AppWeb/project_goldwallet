<?php
require_once '../db_config.php';

$data = getJsonInput();

$from_id = $data['from_wallet_id'];
$to_id = $data['to_wallet_id'];
$amount = (float)$data['amount'];
$note = $data['note'] ?? '';
$date = $data['date'];
$transfer_id = bin2hex(random_bytes(8)); // Simpler transfer ID

$conn->begin_transaction();

try {
    // 1. Debit from wallet A
    $conn->query("UPDATE wallets SET balance = balance - $amount WHERE id = $from_id");
    $stmt1 = $conn->prepare("INSERT INTO transactions (wallet_id, amount, type, note, transfer_id, date) VALUES (?, ?, 'expense', ?, ?, ?)");
    $stmt1->bind_param("idsss", $from_id, $amount, $note, $transfer_id, $date);
    $stmt1->execute();

    // 2. Credit to wallet B
    $conn->query("UPDATE wallets SET balance = balance + $amount WHERE id = $to_id");
    $stmt2 = $conn->prepare("INSERT INTO transactions (wallet_id, amount, type, note, transfer_id, date) VALUES (?, ?, 'income', ?, ?, ?)");
    $stmt2->bind_param("idsss", $to_id, $amount, $note, $transfer_id, $date);
    $stmt2->execute();

    $conn->commit();
    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    $conn->rollback();
    sendError($e->getMessage());
}
?>
