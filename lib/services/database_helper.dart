import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';

import '../core/constants.dart';
import '../core/utils.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // --- DDL ---
    await db.execute('''
      CREATE TABLE ${AppConstants.tableWallets} (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT NOT NULL,
        type       TEXT CHECK(type IN ('cash','bank','e-wallet','gold')) NOT NULL,
        balance    REAL DEFAULT 0.0,
        is_main    INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableCategories} (
        id   INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT CHECK(type IN ('income','expense')) NOT NULL,
        icon TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableTransactions} (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        wallet_id   INTEGER NOT NULL,
        category_id INTEGER,
        amount      REAL NOT NULL,
        type        TEXT CHECK(type IN ('income','expense','transfer')) NOT NULL,
        note        TEXT,
        transfer_id TEXT,
        date        TEXT NOT NULL,
        FOREIGN KEY (wallet_id) REFERENCES ${AppConstants.tableWallets} (id)
          ON DELETE CASCADE
      )
    ''');

    // --- Seed: Dompet Utama ---
    await db.insert(AppConstants.tableWallets, {
      'name': AppConstants.mainWalletName,
      'type': 'cash',
      'balance': 0.0,
      'is_main': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    // --- Seed: Kategori Default ---
    final batch = db.batch();
    for (final cat in defaultCategories) {
      batch.insert(AppConstants.tableCategories, cat);
    }
    await batch.commit(noResult: true);
  }

  Future<void> resetDatabase() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(AppConstants.tableTransactions);
      await txn.delete(AppConstants.tableCategories);
      await txn.delete(AppConstants.tableWallets);

      // Re-seed Wallets
      await txn.insert(AppConstants.tableWallets, {
        'name': AppConstants.mainWalletName,
        'type': 'cash',
        'balance': 0.0,
        'is_main': 1,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Re-seed Categories
      for (final cat in defaultCategories) {
        await txn.insert(AppConstants.tableCategories, cat);
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // WALLET CRUD
  // ─────────────────────────────────────────────────────────────

  Future<List<Wallet>> getWallets() async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableWallets,
      orderBy: 'is_main DESC, created_at ASC',
    );
    return rows.map(Wallet.fromMap).toList();
  }

  Future<Wallet?> getWalletById(int id) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableWallets,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Wallet.fromMap(rows.first);
  }

  Future<int> insertWallet(Wallet wallet) async {
    final db = await database;
    return db.insert(AppConstants.tableWallets, wallet.toMap());
  }

  Future<void> updateWallet(Wallet wallet) async {
    if (wallet.isMain) throw Exception('Dompet Utama tidak dapat diubah.');
    if (wallet.id == null) throw Exception('ID wallet tidak boleh null.');
    final db = await database;
    await db.update(
      AppConstants.tableWallets,
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  Future<void> deleteWallet(Wallet wallet) async {
    if (wallet.isMain) throw Exception('Dompet Utama tidak dapat dihapus.');
    if (wallet.id == null) throw Exception('ID wallet tidak boleh null.');
    final db = await database;
    // ON DELETE CASCADE otomatis menghapus transaksi terkait
    await db.delete(
      AppConstants.tableWallets,
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  Future<void> updateWalletBalance(int walletId, double newBalance,
      {Transaction? txn}) async {
    final executor = txn != null ? (await database) : (await database);
    // Menggunakan txn jika ada, untuk operasi atomic
    await executor.update(
      AppConstants.tableWallets,
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [walletId],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CATEGORY CRUD
  // ─────────────────────────────────────────────────────────────

  Future<List<Category>> getCategories({CategoryType? type}) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableCategories,
      where: type != null ? 'type = ?' : null,
      whereArgs: type != null ? [type.value] : null,
      orderBy: 'name ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return db.insert(AppConstants.tableCategories, category.toMap());
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete(
      AppConstants.tableCategories,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TRANSACTION CRUD
  // ─────────────────────────────────────────────────────────────

  Future<List<Transaction>> getTransactions({
    int? walletId,
    int? limit,
    int? offset,
    DateTime? from,
    DateTime? to,
    TransactionType? type,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (walletId != null) {
      conditions.add('t.wallet_id = ?');
      args.add(walletId);
    }
    if (type != null) {
      conditions.add('t.type = ?');
      args.add(type.value);
    }
    if (from != null) {
      conditions.add("t.date >= ?");
      args.add(DateFormatter.toISO(from));
    }
    if (to != null) {
      conditions.add("t.date <= ?");
      args.add(DateFormatter.toISO(to));
    }

    final where = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';

    final rows = await db.rawQuery('''
      SELECT
        t.*,
        w.name AS wallet_name,
        w.type AS wallet_type,
        w.is_main AS wallet_is_main,
        c.name AS category_name,
        c.icon AS category_icon,
        c.type AS category_type
      FROM ${AppConstants.tableTransactions} t
      LEFT JOIN ${AppConstants.tableWallets} w ON t.wallet_id = w.id
      LEFT JOIN ${AppConstants.tableCategories} c ON t.category_id = c.id
      $where
      ORDER BY t.date DESC
      $limitClause
      $offsetClause
    ''', args);

    return rows.map(_mapRowToTransaction).toList();
  }

  Transaction _mapRowToTransaction(Map<String, dynamic> row) {
    Wallet? wallet;
    if (row['wallet_name'] != null) {
      wallet = Wallet(
        id: row['wallet_id'] as int?,
        name: row['wallet_name'] as String,
        type: WalletTypeExt.fromString(row['wallet_type'] as String),
        isMain: (row['wallet_is_main'] as int?) == 1,
        createdAt: DateTime.now(),
      );
    }

    Category? category;
    if (row['category_name'] != null) {
      category = Category(
        id: row['category_id'] as int?,
        name: row['category_name'] as String,
        icon: row['category_icon'] as String?,
        type: CategoryTypeExt.fromString(row['category_type'] as String? ?? 'expense'),
      );
    }

    return Transaction.fromMap(row).copyWith(wallet: wallet, category: category);
  }

  // ─────────────────────────────────────────────────────────────
  // INCOME / EXPENSE (single transaction)
  // ─────────────────────────────────────────────────────────────

  Future<void> addTransaction(Transaction tx) async {
    final db = await database;
    final wallet = await getWalletById(tx.walletId);
    if (wallet == null) throw Exception('Wallet tidak ditemukan.');

    double newBalance;
    if (tx.isIncome) {
      newBalance = wallet.balance + tx.amount;
    } else if (tx.isExpense) {
      newBalance = wallet.balance - tx.amount;
    } else {
      throw Exception('Gunakan executeTransfer() untuk transaksi transfer.');
    }

    await db.transaction((txnDb) async {
      await txnDb.insert(AppConstants.tableTransactions, tx.toMap());
      await txnDb.update(
        AppConstants.tableWallets,
        {'balance': newBalance},
        where: 'id = ?',
        whereArgs: [tx.walletId],
      );
    });
  }

  Future<void> deleteTransaction(Transaction tx) async {
    if (tx.id == null) return;
    final db = await database;

    if (tx.isTransfer && tx.transferId != null) {
      // Hapus keduanya jika transfer
      await _deleteTransferPair(db, tx);
      return;
    }

    final wallet = await getWalletById(tx.walletId);
    if (wallet == null) return;

    double newBalance;
    if (tx.isIncome) {
      newBalance = wallet.balance - tx.amount;
    } else {
      newBalance = wallet.balance + tx.amount;
    }

    await db.transaction((txnDb) async {
      await txnDb.delete(
        AppConstants.tableTransactions,
        where: 'id = ?',
        whereArgs: [tx.id],
      );
      await txnDb.update(
        AppConstants.tableWallets,
        {'balance': newBalance},
        where: 'id = ?',
        whereArgs: [tx.walletId],
      );
    });
  }

  Future<void> _deleteTransferPair(Database db, Transaction tx) async {
    final pairs = await db.query(
      AppConstants.tableTransactions,
      where: 'transfer_id = ?',
      whereArgs: [tx.transferId],
    );

    await db.transaction((txnDb) async {
      for (final row in pairs) {
        final t = Transaction.fromMap(row);
        final w = await getWalletById(t.walletId);
        if (w == null) continue;

        final newBal = t.isIncome ? w.balance - t.amount : w.balance + t.amount;
        await txnDb.update(
          AppConstants.tableWallets,
          {'balance': newBal},
          where: 'id = ?',
          whereArgs: [t.walletId],
        );
      }
      await txnDb.delete(
        AppConstants.tableTransactions,
        where: 'transfer_id = ?',
        whereArgs: [tx.transferId],
      );
    });
  }

  // ─────────────────────────────────────────────────────────────
  // ATOMIC TRANSFER
  // ─────────────────────────────────────────────────────────────

  Future<void> executeTransfer({
    required int fromWalletId,
    required int toWalletId,
    required double amount,
    String? note,
    DateTime? date,
  }) async {
    final db = await database;
    final fromWallet = await getWalletById(fromWalletId);
    final toWallet = await getWalletById(toWalletId);

    if (fromWallet == null) throw Exception('Dompet sumber tidak ditemukan.');
    if (toWallet == null) throw Exception('Dompet tujuan tidak ditemukan.');
    if (fromWallet.balance < amount) {
      throw Exception('Saldo di ${fromWallet.name} tidak mencukupi.');
    }
    if (fromWalletId == toWalletId) {
      throw Exception('Tidak bisa transfer ke dompet yang sama.');
    }

    final transferId = IdGenerator.transferId();
    final txDate = DateFormatter.toISO(date ?? DateTime.now());
    final newFromBalance = fromWallet.balance - amount;
    final newToBalance = toWallet.balance + amount;

    await db.transaction((txn) async {
      // Debit dari dompet A
      await txn.rawUpdate(
        'UPDATE ${AppConstants.tableWallets} SET balance = ? WHERE id = ?',
        [newFromBalance, fromWalletId],
      );
      await txn.insert(AppConstants.tableTransactions, {
        'wallet_id': fromWalletId,
        'amount': amount,
        'type': 'expense',
        'note': note,
        'transfer_id': transferId,
        'date': txDate,
      });

      // Kredit ke dompet B
      await txn.rawUpdate(
        'UPDATE ${AppConstants.tableWallets} SET balance = ? WHERE id = ?',
        [newToBalance, toWalletId],
      );
      await txn.insert(AppConstants.tableTransactions, {
        'wallet_id': toWalletId,
        'amount': amount,
        'type': 'income',
        'note': note,
        'transfer_id': transferId,
        'date': txDate,
      });
    });
  }

  // ─────────────────────────────────────────────────────────────
  // GOLD: Beli emas (expense IDR → income GRAM)
  // ─────────────────────────────────────────────────────────────

  Future<void> buyGold({
    required int cashWalletId,
    required int goldWalletId,
    required double idrAmount,
    required double gramAmount,
    String? note,
    DateTime? date,
  }) async {
    final db = await database;
    final cashWallet = await getWalletById(cashWalletId);
    final goldWallet = await getWalletById(goldWalletId);

    if (cashWallet == null) throw Exception('Dompet sumber tidak ditemukan.');
    if (goldWallet == null) throw Exception('Dompet emas tidak ditemukan.');
    if (!goldWallet.isGold) throw Exception('Dompet tujuan bukan tipe emas.');
    if (cashWallet.balance < idrAmount) {
      throw Exception('Saldo di ${cashWallet.name} tidak mencukupi.');
    }

    final transferId = IdGenerator.transferId();
    final txDate = DateFormatter.toISO(date ?? DateTime.now());
    final newCashBalance = cashWallet.balance - idrAmount;
    final newGoldBalance = goldWallet.balance + gramAmount;

    await db.transaction((txn) async {
      // Kurangi saldo cash (dalam IDR)
      await txn.rawUpdate(
        'UPDATE ${AppConstants.tableWallets} SET balance = ? WHERE id = ?',
        [newCashBalance, cashWalletId],
      );
      await txn.insert(AppConstants.tableTransactions, {
        'wallet_id': cashWalletId,
        'amount': idrAmount,
        'type': 'expense',
        'note': note ?? 'Beli emas ${gramAmount}gr',
        'transfer_id': transferId,
        'date': txDate,
      });

      // Tambah saldo gold (dalam GRAM)
      await txn.rawUpdate(
        'UPDATE ${AppConstants.tableWallets} SET balance = ? WHERE id = ?',
        [newGoldBalance, goldWalletId],
      );
      await txn.insert(AppConstants.tableTransactions, {
        'wallet_id': goldWalletId,
        'amount': gramAmount,
        'type': 'income',
        'note': note ?? 'Beli emas ${gramAmount}gr',
        'transfer_id': transferId,
        'date': txDate,
      });
    });
  }

  // ─────────────────────────────────────────────────────────────
  // SUMMARY / ANALYTICS
  // ─────────────────────────────────────────────────────────────

  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final result = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN type = 'income' AND transfer_id IS NULL THEN amount ELSE 0 END) AS total_income,
        SUM(CASE WHEN type = 'expense' AND transfer_id IS NULL THEN amount ELSE 0 END) AS total_expense
      FROM ${AppConstants.tableTransactions}
      WHERE date BETWEEN ? AND ?
    ''', [DateFormatter.toISO(startDate), DateFormatter.toISO(endDate)]);

    return {
      'income': (result.first['total_income'] as num?)?.toDouble() ?? 0.0,
      'expense': (result.first['total_expense'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getExpenseByCategory(
      int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return db.rawQuery('''
      SELECT
        c.name AS category,
        c.icon AS icon,
        SUM(t.amount) AS total
      FROM ${AppConstants.tableTransactions} t
      LEFT JOIN ${AppConstants.tableCategories} c ON t.category_id = c.id
      WHERE t.type = 'expense'
        AND t.transfer_id IS NULL
        AND t.date BETWEEN ? AND ?
      GROUP BY t.category_id
      ORDER BY total DESC
    ''', [DateFormatter.toISO(startDate), DateFormatter.toISO(endDate)]);
  }

  Future<List<Map<String, dynamic>>> getDailyExpenses(
      int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return db.rawQuery('''
      SELECT
        substr(date, 1, 10) AS day,
        SUM(CASE WHEN type = 'expense' AND transfer_id IS NULL THEN amount ELSE 0 END) AS expense,
        SUM(CASE WHEN type = 'income' AND transfer_id IS NULL THEN amount ELSE 0 END) AS income
      FROM ${AppConstants.tableTransactions}
      WHERE date BETWEEN ? AND ?
      GROUP BY substr(date, 1, 10)
      ORDER BY day ASC
    ''', [DateFormatter.toISO(startDate), DateFormatter.toISO(endDate)]);
  }
}
