<?php
require_once '../db_config.php';

$type = $_GET['type'] ?? null;
$sql = "SELECT * FROM categories";
if ($type) {
    $sql .= " WHERE type = '$type'";
}
$sql .= " ORDER BY name ASC";

$result = $conn->query($sql);
$categories = [];
if ($result) {
    while($row = $result->fetch_assoc()) {
        $row['id'] = (int)$row['id'];
        $categories[] = $row;
    }
}

echo json_encode($categories);
?>
