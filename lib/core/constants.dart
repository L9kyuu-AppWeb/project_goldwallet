class AppConstants {
  static const String dbName = 'gold_wallet.db';
  static const int dbVersion = 1;
  static const String mainWalletName = 'Dompet Utama';

  // Table names
  static const String tableWallets = 'wallets';
  static const String tableCategories = 'categories';
  static const String tableTransactions = 'transactions';
}

enum WalletType { cash, bank, eWallet, gold }

extension WalletTypeExt on WalletType {
  String get value {
    switch (this) {
      case WalletType.cash: return 'cash';
      case WalletType.bank: return 'bank';
      case WalletType.eWallet: return 'e-wallet';
      case WalletType.gold: return 'gold';
    }
  }

  String get label {
    switch (this) {
      case WalletType.cash: return 'Tunai';
      case WalletType.bank: return 'Bank';
      case WalletType.eWallet: return 'E-Wallet';
      case WalletType.gold: return 'Emas';
    }
  }

  String get emoji {
    switch (this) {
      case WalletType.cash: return '💵';
      case WalletType.bank: return '🏦';
      case WalletType.eWallet: return '📱';
      case WalletType.gold: return '🪙';
    }
  }

  bool get isGold => this == WalletType.gold;

  static WalletType fromString(String value) {
    switch (value) {
      case 'cash': return WalletType.cash;
      case 'bank': return WalletType.bank;
      case 'e-wallet': return WalletType.eWallet;
      case 'gold': return WalletType.gold;
      default: return WalletType.cash;
    }
  }
}

enum TransactionType { income, expense, transfer }

extension TransactionTypeExt on TransactionType {
  String get value {
    switch (this) {
      case TransactionType.income: return 'income';
      case TransactionType.expense: return 'expense';
      case TransactionType.transfer: return 'transfer';
    }
  }

  String get label {
    switch (this) {
      case TransactionType.income: return 'Pemasukan';
      case TransactionType.expense: return 'Pengeluaran';
      case TransactionType.transfer: return 'Transfer';
    }
  }

  static TransactionType fromString(String value) {
    switch (value) {
      case 'income': return TransactionType.income;
      case 'expense': return TransactionType.expense;
      case 'transfer': return TransactionType.transfer;
      default: return TransactionType.expense;
    }
  }
}

enum CategoryType { income, expense }

extension CategoryTypeExt on CategoryType {
  String get value => this == CategoryType.income ? 'income' : 'expense';

  static CategoryType fromString(String v) =>
      v == 'income' ? CategoryType.income : CategoryType.expense;
}
