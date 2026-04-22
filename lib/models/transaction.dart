import '../core/constants.dart';
import '../core/utils.dart';
import 'category.dart';
import 'wallet.dart';

class Transaction {
  final int? id;
  final int walletId;
  final int? categoryId;
  final double amount;
  final TransactionType type;
  final String? note;
  final String? transferId;
  final DateTime date;

  // Joined relations (tidak disimpan di DB)
  final Wallet? wallet;
  final Category? category;

  const Transaction({
    this.id,
    required this.walletId,
    this.categoryId,
    required this.amount,
    required this.type,
    this.note,
    this.transferId,
    required this.date,
    this.wallet,
    this.category,
  });

  bool get isTransfer => type == TransactionType.transfer;
  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  Transaction copyWith({
    int? id,
    int? walletId,
    int? categoryId,
    double? amount,
    TransactionType? type,
    String? note,
    String? transferId,
    DateTime? date,
    Wallet? wallet,
    Category? category,
  }) {
    return Transaction(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
      transferId: transferId ?? this.transferId,
      date: date ?? this.date,
      wallet: wallet ?? this.wallet,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'wallet_id': walletId,
      'category_id': categoryId,
      'amount': amount,
      'type': type.value,
      'note': note,
      'transfer_id': transferId,
      'date': DateFormatter.toISO(date),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    // Parse joined wallet if data exists
    Wallet? wallet;
    if (map['wallet_name'] != null) {
      wallet = Wallet(
        id: map['wallet_id'] as int?,
        name: map['wallet_name'] as String,
        type: WalletTypeExt.fromString(map['wallet_type'] as String),
        isMain: map['wallet_is_main'] is bool 
            ? map['wallet_is_main'] as bool 
            : (map['wallet_is_main'] as int?) == 1,
        createdAt: DateTime.now(), // Placeholder
      );
    }

    // Parse joined category if data exists
    Category? category;
    if (map['category_name'] != null) {
      category = Category(
        id: map['category_id'] as int?,
        name: map['category_name'] as String,
        icon: map['category_icon'] as String?,
        type: CategoryTypeExt.fromString(map['category_type'] as String? ?? 'expense'),
      );
    }

    return Transaction(
      id: map['id'] as int?,
      walletId: map['wallet_id'] as int,
      categoryId: map['category_id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionTypeExt.fromString(map['type'] as String),
      note: map['note'] as String?,
      transferId: map['transfer_id'] as String?,
      date: DateFormatter.fromISO(map['date'] as String),
      wallet: wallet,
      category: category,
    );
  }

  @override
  String toString() =>
      'Transaction(id: $id, amount: $amount, type: ${type.value}, date: $date)';
}
