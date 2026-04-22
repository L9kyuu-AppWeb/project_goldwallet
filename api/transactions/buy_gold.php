<?php
require_once '../db_config.php';

$data = getJsonInput();

$cash_id = $data['cash_wallet_id'];
$gold_id = $data['gold_wallet_id'];
$idr_amount = (float)$data['idr_amount'];
$gram_amount = (float)$data['gram_amount'];
$note = $data['note'] ?? '';
$date = $data['date'];
$transfer_id = bin2hex(random_bytes(8));

$conn->begin_transaction();

try {
    // 1. Debit Cash
    $conn->query("UPDATE wallets SET balance = balance - $idr_amount WHERE id = $cash_id");
    $stmt1 = $conn->prepare("INSERT INTO transactions (wallet_id, amount, type, note, transfer_id, date) VALUES (?, ?, 'expense', ?, ?, ?)");
    $stmt1->bind_param("idsss", $cash_id, $idr_amount, $note, $transfer_id, $date);
    $stmt1->execute();

    // 2. Credit Gold
    $conn->query("UPDATE wallets SET balance = balance + $gram_amount WHERE id = $gold_id");
    $stmt2 = $conn->prepare("INSERT INTO transactions (wallet_id, amount, type, note, transfer_id, date) VALUES (?, ?, 'income', ?, ?, ?)");
    $stmt2->bind_param("idsss", $gold_id, $gram_amount, $note, $transfer_id, $date);
    $stmt2->execute();

    $conn->commit();
    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    $conn->rollback();
    sendError($e->getMessage());
}
?>
