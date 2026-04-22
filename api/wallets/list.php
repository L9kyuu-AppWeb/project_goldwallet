<?php
require_once '../db_config.php';

$sql = "SELECT * FROM wallets ORDER BY is_main DESC, created_at ASC";
$result = $conn->query($sql);

$wallets = [];
if ($result) {
    while($row = $result->fetch_assoc()) {
        $row['id'] = (int)$row['id'];
        $row['balance'] = (float)$row['balance'];
        $row['is_main'] = (int)$row['is_main'];
        $wallets[] = $row;
    }
}

echo json_encode($wallets);
?>
