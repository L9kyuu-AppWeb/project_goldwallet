import 'package:flutter/material.dart';
import '../core/utils.dart';
import '../models/wallet.dart';
import '../services/database_helper.dart';

class WalletProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Wallet> _wallets = [];
  bool _isLoading = false;
  String? _error;
  double _goldPricePerGram = GoldCalculator.defaultPricePerGram;

  List<Wallet> get wallets => _wallets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get goldPricePerGram => _goldPricePerGram;

  Wallet? get mainWallet =>
      _wallets.where((w) => w.isMain).firstOrNull;

  List<Wallet> get nonGoldWallets =>
      _wallets.where((w) => !w.isGold).toList();

  List<Wallet> get goldWallets =>
      _wallets.where((w) => w.isGold).toList();

  /// Total saldo semua dompet dalam IDR (emas dikonversi)
  double get totalBalanceIDR {
    double total = 0;
    for (final w in _wallets) {
      if (w.isGold) {
        total += GoldCalculator.toIDR(w.balance, _goldPricePerGram);
      } else {
        total += w.balance;
      }
    }
    return total;
  }

  /// Total gram emas
  double get totalGoldGram =>
      _wallets.where((w) => w.isGold).fold(0.0, (sum, w) => sum + w.balance);

  Future<void> loadWallets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _wallets = await _db.getWallets();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addWallet(Wallet wallet) async {
    try {
      final id = await _db.insertWallet(wallet);
      _wallets.add(wallet.copyWith(id: id));
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateWallet(Wallet wallet) async {
    try {
      await _db.updateWallet(wallet);
      final idx = _wallets.indexWhere((w) => w.id == wallet.id);
      if (idx != -1) {
        _wallets[idx] = wallet;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWallet(Wallet wallet) async {
    try {
      await _db.deleteWallet(wallet);
      _wallets.removeWhere((w) => w.id == wallet.id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void updateGoldPrice(double price) {
    if (price <= 0) return;
    _goldPricePerGram = price;
    notifyListeners();
  }

  double walletValueIDR(Wallet wallet) {
    if (wallet.isGold) {
      return GoldCalculator.toIDR(wallet.balance, _goldPricePerGram);
    }
    return wallet.balance;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
