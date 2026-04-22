<?php
require_once '../db_config.php';

$year = $_GET['year'] ?? date('Y');
$month = $_GET['month'] ?? date('m');

$start = "$year-$month-01 00:00:00";
$end = date("Y-m-t 23:59:59", strtotime($start));

$sql = "SELECT 
            DATE(date) AS day,
            SUM(CASE WHEN type = 'expense' AND transfer_id IS NULL THEN amount ELSE 0 END) AS expense,
            SUM(CASE WHEN type = 'income' AND transfer_id IS NULL THEN amount ELSE 0 END) AS income
        FROM transactions
        WHERE date BETWEEN '$start' AND '$end'
        GROUP BY DATE(date)
        ORDER BY day ASC";

$result = $conn->query($sql);
$data = [];
if ($result) {
    while($row = $result->fetch_assoc()) {
        $row['expense'] = (float)$row['expense'];
        $row['income'] = (float)$row['income'];
        $data[] = $row;
    }
}

echo json_encode($data);
?>
