<?php
require_once '../db_config.php';

$year = $_GET['year'] ?? date('Y');
$month = $_GET['month'] ?? date('m');

$start = "$year-$month-01 00:00:00";
$end = date("Y-m-t 23:59:59", strtotime($start));

$sql = "SELECT 
            SUM(CASE WHEN type = 'income' AND transfer_id IS NULL THEN amount ELSE 0 END) AS income,
            SUM(CASE WHEN type = 'expense' AND transfer_id IS NULL THEN amount ELSE 0 END) AS expense
        FROM transactions 
        WHERE date BETWEEN '$start' AND '$end'";

$result = $conn->query($sql);
$summary = $result->fetch_assoc();

echo json_encode([
    "income" => (float)$summary['income'],
    "expense" => (float)$summary['expense']
]);
?>
