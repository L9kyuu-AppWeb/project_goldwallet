<?php
require_once 'db_config.php';

$conn->query("SET FOREIGN_KEY_CHECKS = 0");
$conn->query("TRUNCATE TABLE transactions");
$conn->query("TRUNCATE TABLE categories");
$conn->query("TRUNCATE TABLE wallets");
$conn->query("SET FOREIGN_KEY_CHECKS = 1");

// Seed Wallets
$conn->query("INSERT INTO wallets (name, type, balance, is_main) VALUES ('Dompet Utama', 'cash', 0.0, 1)");

// Seed Categories
$conn->query("INSERT INTO categories (name, type, icon) VALUES 
('Gaji', 'income', 'money-receive'),
('Bonus', 'income', 'percentage_square'),
('Makan & Minum', 'expense', 'cake'),
('Transportasi', 'expense', 'bus'),
('Belanja', 'expense', 'shopping_bag'),
('Entertainment', 'expense', 'box_2'),
('Kesehatan', 'expense', 'health'),
('Tagihan', 'expense', 'bill'),
('Pendidikan', 'expense', 'book'),
('Lain-lain', 'expense', 'more_square')");

echo json_encode(["status" => "success", "message" => "Database reset successfully"]);
?>
