<?php
require_once '../db_config.php';

$data = getJsonInput();
$id = $data['id'] ?? null;
$transfer_id = $data['transfer_id'] ?? null;

$conn->begin_transaction();

try {
    if ($transfer_id) {
        // Handle deletion of transfer pairs
        $res = $conn->query("SELECT * FROM transactions WHERE transfer_id = '$transfer_id'");
        while($tx = $res->fetch_assoc()) {
            $w_id = $tx['wallet_id'];
            $amt = $tx['amount'];
            if ($tx['type'] === 'income') {
                $conn->query("UPDATE wallets SET balance = balance - $amt WHERE id = $w_id");
            } else {
                $conn->query("UPDATE wallets SET balance = balance + $amt WHERE id = $w_id");
            }
        }
        $conn->query("DELETE FROM transactions WHERE transfer_id = '$transfer_id'");
    } else if ($id) {
        $res = $conn->query("SELECT * FROM transactions WHERE id = $id");
        $tx = $res->fetch_assoc();
        if ($tx) {
            $w_id = $tx['wallet_id'];
            $amt = $tx['amount'];
            if ($tx['type'] === 'income') {
                $conn->query("UPDATE wallets SET balance = balance - $amt WHERE id = $w_id");
            } else {
                $conn->query("UPDATE wallets SET balance = balance + $amt WHERE id = $w_id");
            }
            $conn->query("DELETE FROM transactions WHERE id = $id");
        }
    }

    $conn->commit();
    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    $conn->rollback();
    sendError($e->getMessage());
}
?>
