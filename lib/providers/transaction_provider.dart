import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../services/database_helper.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  // Filter state
  int? _filterWalletId;
  TransactionType? _filterType;
  DateTime _filterMonth = DateTime.now();

  List<Transaction> get transactions => _transactions;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get filterMonth => _filterMonth;
  int? get filterWalletId => _filterWalletId;

  List<Category> get expenseCategories =>
      _categories.where((c) => c.type == CategoryType.expense).toList();

  List<Category> get incomeCategories =>
      _categories.where((c) => c.type == CategoryType.income).toList();

  double get totalIncome => _transactions
      .where((t) => t.isIncome && t.transferId == null)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.isExpense && t.transferId == null)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  Future<void> loadAll() async {
    await Future.wait([loadTransactions(), loadCategories()]);
  }

  Future<void> loadTransactions({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    _error = null;
    try {
      _transactions = await _db.getTransactions(
        walletId: _filterWalletId,
        from: DateTime(_filterMonth.year, _filterMonth.month, 1),
        to: DateTime(_filterMonth.year, _filterMonth.month + 1, 0, 23, 59, 59),
        type: _filterType,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _db.getCategories();
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<bool> addTransaction(Transaction tx) async {
    _error = null;
    try {
      await _db.addTransaction(tx);
      // We don't return false if reload fails, because the transaction was saved
      try {
        await loadTransactions(silent: true);
      } catch (_) {}
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> executeTransfer({
    required Wallet fromWallet,
    required Wallet toWallet,
    required double amount,
    String? note,
    DateTime? date,
  }) async {
    _error = null;
    try {
      await _db.executeTransfer(
        fromWalletId: fromWallet.id!,
        toWalletId: toWallet.id!,
        amount: amount,
        note: note,
        date: date,
      );
      try {
        await loadTransactions(silent: true);
      } catch (_) {}
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> buyGold({
    required Wallet cashWallet,
    required Wallet goldWallet,
    required double idrAmount,
    required double gramAmount,
    String? note,
    DateTime? date,
  }) async {
    _error = null;
    try {
      await _db.buyGold(
        cashWalletId: cashWallet.id!,
        goldWalletId: goldWallet.id!,
        idrAmount: idrAmount,
        gramAmount: gramAmount,
        note: note,
        date: date,
      );
      try {
        await loadTransactions(silent: true);
      } catch (_) {}
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(Transaction tx) async {
    _error = null;
    
    // Remove locally first to avoid Dismissible tree errors
    final index = _transactions.indexWhere((t) => t.id == tx.id);
    if (index != -1) {
      _transactions.removeAt(index);
      notifyListeners();
    }

    try {
      await _db.deleteTransaction(tx);
      try {
        await loadTransactions(silent: true);
      } catch (_) {}
      return true;
    } catch (e) {
      _error = e.toString();
      // Reload on failure to restore the item to the list
      await loadTransactions(silent: true);
      notifyListeners();
      return false;
    }
  }

  void setFilterMonth(DateTime month) {
    _filterMonth = month;
    loadTransactions();
  }

  void setFilterWallet(int? walletId) {
    _filterWalletId = walletId;
    loadTransactions();
  }

  void setFilterType(TransactionType? type) {
    _filterType = type;
    loadTransactions();
  }

  Future<Map<String, double>> getMonthlySummary() async {
    return _db.getMonthlySummary(_filterMonth.year, _filterMonth.month);
  }

  Future<List<Map<String, dynamic>>> getExpenseByCategory() async {
    return _db.getExpenseByCategory(_filterMonth.year, _filterMonth.month);
  }

  Future<List<Map<String, dynamic>>> getDailyChart() async {
    return _db.getDailyExpenses(_filterMonth.year, _filterMonth.month);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
