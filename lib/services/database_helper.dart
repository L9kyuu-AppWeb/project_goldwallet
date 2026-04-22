import '../core/constants.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import 'api_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  final ApiService _api = ApiService.instance;

  // Note: 'database' getter is no longer used for SQLite but kept for compatibility if needed.
  // In this HTTP version, we don't need a local DB instance.
  Future<dynamic> get database async => null;

  Future<void> resetDatabase() async {
    await _api.post('reset_db.php', {});
  }

  // ─────────────────────────────────────────────────────────────
  // WALLET CRUD
  // ─────────────────────────────────────────────────────────────

  Future<List<Wallet>> getWallets() async {
    final response = await _api.get('wallets/list.php');
    if (response is List) {
      return response.map((json) => Wallet.fromMap(json)).toList();
    }
    return [];
  }

  Future<Wallet?> getWalletById(int id) async {
    final response = await _api.get('wallets/get.php', queryParams: {'id': id.toString()});
    if (response != null) {
      return Wallet.fromMap(response);
    }
    return null;
  }

  Future<int> insertWallet(Wallet wallet) async {
    final response = await _api.post('wallets/add.php', wallet.toMap());
    return response['id'] as int;
  }

  Future<void> updateWallet(Wallet wallet) async {
    if (wallet.isMain) throw Exception('Dompet Utama tidak dapat diubah.');
    if (wallet.id == null) throw Exception('ID wallet tidak boleh null.');
    await _api.post('wallets/update.php', wallet.toMap());
  }

  Future<void> deleteWallet(Wallet wallet) async {
    if (wallet.isMain) throw Exception('Dompet Utama tidak dapat dihapus.');
    if (wallet.id == null) throw Exception('ID wallet tidak boleh null.');
    await _api.post('wallets/delete.php', {'id': wallet.id});
  }

  // ─────────────────────────────────────────────────────────────
  // CATEGORY CRUD
  // ─────────────────────────────────────────────────────────────

  Future<List<Category>> getCategories({CategoryType? type}) async {
    final Map<String, String> params = {};
    if (type != null) params['type'] = type.value;
    
    final response = await _api.get('categories/list.php', queryParams: params);
    if (response is List) {
      return response.map((json) => Category.fromMap(json)).toList();
    }
    return [];
  }

  Future<int> insertCategory(Category category) async {
    final response = await _api.post('categories/add.php', category.toMap());
    return response['id'] as int;
  }

  Future<void> deleteCategory(int id) async {
    await _api.post('categories/delete.php', {'id': id});
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
    final Map<String, String> params = {};
    if (walletId != null) params['wallet_id'] = walletId.toString();
    if (limit != null) params['limit'] = limit.toString();
    if (offset != null) params['offset'] = offset.toString();
    if (from != null) params['from'] = from.toIso8601String();
    if (to != null) params['to'] = to.toIso8601String();
    if (type != null) params['type'] = type.value;

    final response = await _api.get('transactions/list.php', queryParams: params);
    if (response is List) {
      return response.map((json) => Transaction.fromMap(json)).toList();
    }
    return [];
  }

  Future<void> addTransaction(Transaction tx) async {
    await _api.post('transactions/add.php', tx.toMap());
  }

  Future<void> deleteTransaction(Transaction tx) async {
    if (tx.id == null) return;
    await _api.post('transactions/delete.php', {'id': tx.id, 'transfer_id': tx.transferId});
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
    await _api.post('transactions/transfer.php', {
      'from_wallet_id': fromWalletId,
      'to_wallet_id': toWalletId,
      'amount': amount,
      'note': note,
      'date': (date ?? DateTime.now()).toIso8601String(),
    });
  }

  // ─────────────────────────────────────────────────────────────
  // GOLD: Beli emas
  // ─────────────────────────────────────────────────────────────

  Future<void> buyGold({
    required int cashWalletId,
    required int goldWalletId,
    required double idrAmount,
    required double gramAmount,
    String? note,
    DateTime? date,
  }) async {
    await _api.post('transactions/buy_gold.php', {
      'cash_wallet_id': cashWalletId,
      'gold_wallet_id': goldWalletId,
      'idr_amount': idrAmount,
      'gram_amount': gramAmount,
      'note': note,
      'date': (date ?? DateTime.now()).toIso8601String(),
    });
  }

  // ─────────────────────────────────────────────────────────────
  // SUMMARY / ANALYTICS
  // ─────────────────────────────────────────────────────────────

  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    final response = await _api.get('analytics/monthly_summary.php', queryParams: {
      'year': year.toString(),
      'month': month.toString(),
    });
    return {
      'income': (response['income'] as num?)?.toDouble() ?? 0.0,
      'expense': (response['expense'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getExpenseByCategory(int year, int month) async {
    final response = await _api.get('analytics/expense_by_category.php', queryParams: {
      'year': year.toString(),
      'month': month.toString(),
    });
    if (response is List) {
      return response.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getDailyExpenses(int year, int month) async {
    final response = await _api.get('analytics/daily_expenses.php', queryParams: {
      'year': year.toString(),
      'month': month.toString(),
    });
    if (response is List) {
      return response.cast<Map<String, dynamic>>();
    }
    return [];
  }
}
