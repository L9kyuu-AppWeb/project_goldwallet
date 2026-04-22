<?php
require_once '../db_config.php';

$year = $_GET['year'] ?? date('Y');
$month = $_GET['month'] ?? date('m');

$start = "$year-$month-01 00:00:00";
$end = date("Y-m-t 23:59:59", strtotime($start));

$sql = "SELECT 
            c.name AS category, 
            c.icon AS icon, 
            SUM(t.amount) AS total
        FROM transactions t
        LEFT JOIN categories c ON t.category_id = c.id
        WHERE t.type = 'expense' 
          AND t.transfer_id IS NULL 
          AND t.date BETWEEN '$start' AND '$end'
        GROUP BY t.category_id
        ORDER BY total DESC";

$result = $conn->query($sql);
$data = [];
if ($result) {
    while($row = $result->fetch_assoc()) {
        $row['total'] = (float)$row['total'];
        $data[] = $row;
    }
}

echo json_encode($data);
?>
