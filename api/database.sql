-- Gold Wallet Database Schema

CREATE DATABASE IF NOT EXISTS gold_wallet;
USE gold_wallet;

-- 1. Table Wallets
CREATE TABLE IF NOT EXISTS wallets (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    type       ENUM('cash','bank','e-wallet','gold') NOT NULL,
    balance    DECIMAL(15, 2) DEFAULT 0.0,
    is_main    TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Table Categories
CREATE TABLE IF NOT EXISTS categories (
    id   INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type ENUM('income','expense') NOT NULL,
    icon VARCHAR(50)
);

-- 3. Table Transactions
CREATE TABLE IF NOT EXISTS transactions (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    wallet_id   INT NOT NULL,
    category_id INT,
    amount      DECIMAL(15, 2) NOT NULL,
    type        ENUM('income','expense','transfer') NOT NULL,
    note        TEXT,
    transfer_id VARCHAR(50),
    date        DATETIME NOT NULL,
    FOREIGN KEY (wallet_id) REFERENCES wallets(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
);

-- Seed Data
INSERT INTO wallets (name, type, balance, is_main) VALUES ('Dompet Utama', 'cash', 0.0, 1);

INSERT INTO categories (name, type, icon) VALUES 
('Gaji', 'income', 'money-receive'),
('Bonus', 'income', 'percentage_square'),
('Makan & Minum', 'expense', 'cake'),
('Transportasi', 'expense', 'bus'),
('Belanja', 'expense', 'shopping_bag'),
('Entertainment', 'expense', 'box_2'),
('Kesehatan', 'expense', 'health'),
('Tagihan', 'expense', 'bill'),
('Pendidikan', 'expense', 'book'),
('Lain-lain', 'expense', 'more_square');
