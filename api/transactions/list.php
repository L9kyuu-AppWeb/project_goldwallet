<?php
require_once '../db_config.php';

$wallet_id = $_GET['wallet_id'] ?? null;
$limit = $_GET['limit'] ?? null;
$offset = $_GET['offset'] ?? null;
$from = $_GET['from'] ?? null;
$to = $_GET['to'] ?? null;
$type = $_GET['type'] ?? null;

$where = [];
if ($wallet_id) $where[] = "t.wallet_id = $wallet_id";
if ($type) $where[] = "t.type = '$type'";
if ($from) $where[] = "t.date >= '$from'";
if ($to) $where[] = "t.date <= '$to'";

$where_clause = count($where) > 0 ? "WHERE " . implode(" AND ", $where) : "";
$limit_clause = $limit ? "LIMIT $limit" : "";
$offset_clause = $offset ? "OFFSET $offset" : "";

$sql = "SELECT 
            t.*, 
            w.name AS wallet_name, 
            w.type AS wallet_type, 
            w.is_main AS wallet_is_main,
            c.name AS category_name,
            c.icon AS category_icon,
            c.type AS category_type
        FROM transactions t
        LEFT JOIN wallets w ON t.wallet_id = w.id
        LEFT JOIN categories c ON t.category_id = c.id
        $where_clause
        ORDER BY t.date DESC
        $limit_clause $offset_clause";

$result = $conn->query($sql);
$transactions = [];
if ($result) {
    while($row = $result->fetch_assoc()) {
        $row['id'] = (int)$row['id'];
        $row['wallet_id'] = (int)$row['wallet_id'];
        $row['category_id'] = $row['category_id'] ? (int)$row['category_id'] : null;
        $row['amount'] = (float)$row['amount'];
        $row['wallet_is_main'] = (int)$row['wallet_is_main'];
        $transactions[] = $row;
    }
}

echo json_encode($transactions);
?>
