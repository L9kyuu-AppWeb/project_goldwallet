import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../core/constants.dart';
import '../models/transaction.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onDelete,
  });

  Color get _typeColor {
    if (transaction.isTransfer) return AppColors.transfer;
    if (transaction.isIncome) return AppColors.income;
    return AppColors.expense;
  }

  String get _typeIcon {
    if (transaction.isTransfer) return '↔';
    if (transaction.isIncome) return '↑';
    return '↓';
  }

  String get _categoryName {
    if (transaction.isTransfer) return 'Transfer';
    return transaction.category?.name ?? 'Tidak ada kategori';
  }

  String get _amountDisplay {
    final wallet = transaction.wallet;
    final isGoldWallet = wallet?.isGold ?? false;

    if (isGoldWallet && transaction.isIncome) {
      return '+${CurrencyFormatter.formatGram(transaction.amount)}';
    }
    if (isGoldWallet && transaction.isExpense && !transaction.isTransfer) {
      return '-${CurrencyFormatter.formatGram(transaction.amount)}';
    }

    final prefix = transaction.isIncome ? '+' : '-';
    return '$prefix${CurrencyFormatter.formatIDR(transaction.amount)}';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('tx_${transaction.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        if (onDelete == null) return false;
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceAlt,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: const Text(
              'Hapus Transaksi?',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            content: Text(
              transaction.isTransfer
                  ? 'Menghapus transfer akan membatalkan kedua sisi transaksi.'
                  : 'Saldo akan dikembalikan secara otomatis.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.expense,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.expense),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Type indicator
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _typeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text(
                  _typeIcon,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _typeColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Main info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _categoryName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          transaction.wallet?.name ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (transaction.note != null &&
                          transaction.note!.isNotEmpty) ...[
                        const Text(
                          ' · ',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        Expanded(
                          child: Text(
                            transaction.note!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Amount + date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _amountDisplay,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _typeColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.toShort(transaction.date),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
