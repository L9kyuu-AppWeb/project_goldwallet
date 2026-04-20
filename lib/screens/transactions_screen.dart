import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../core/constants.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/shared_widgets.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final walletProvider = context.watch<WalletProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            onPressed: () => _showFilterSheet(context, txProvider, walletProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // MONTH NAVIGATOR
          _MonthNavigator(
            month: txProvider.filterMonth,
            onPrev: () => txProvider.setFilterMonth(DateTime(
              txProvider.filterMonth.year,
              txProvider.filterMonth.month - 1,
            )),
            onNext: () => txProvider.setFilterMonth(DateTime(
              txProvider.filterMonth.year,
              txProvider.filterMonth.month + 1,
            )),
          ),

          // SUMMARY ROW
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _MiniStat(
                  label: 'Masuk',
                  value: CurrencyFormatter.formatCompact(txProvider.totalIncome),
                  color: AppColors.income,
                ),
                const SizedBox(width: 12),
                _MiniStat(
                  label: 'Keluar',
                  value: CurrencyFormatter.formatCompact(txProvider.totalExpense),
                  color: AppColors.expense,
                ),
                const SizedBox(width: 12),
                _MiniStat(
                  label: 'Net',
                  value: CurrencyFormatter.formatCompact(txProvider.balance),
                  color: txProvider.balance >= 0
                      ? AppColors.income
                      : AppColors.expense,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // TRANSACTION LIST
          Expanded(
            child: txProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : txProvider.transactions.isEmpty
                    ? const EmptyState(
                        emoji: '📋',
                        title: 'Tidak ada transaksi',
                        subtitle: 'Belum ada transaksi di bulan ini',
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => txProvider.loadTransactions(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                          itemCount: txProvider.transactions.length,
                          itemBuilder: (ctx, i) {
                            final tx = txProvider.transactions[i];
                            return TransactionTile(
                              transaction: tx,
                              onDelete: () async {
                                final ok = await txProvider.deleteTransaction(tx);
                                if (ok && ctx.mounted) {
                                  walletProvider.loadWallets();
                                  showSuccessSnack(ctx, 'Transaksi dihapus');
                                } else if (ctx.mounted && txProvider.error != null) {
                                  showErrorSnack(ctx, txProvider.error!);
                                  txProvider.clearError();
                                }
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(
    BuildContext context,
    TransactionProvider txProvider,
    WalletProvider walletProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dompet',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'Semua',
                  isSelected: txProvider.filterWalletId == null,
                  onTap: () {
                    txProvider.setFilterWallet(null);
                    Navigator.pop(ctx);
                  },
                ),
                ...walletProvider.wallets.map(
                  (w) => _FilterChip(
                    label: '${w.type.emoji} ${w.name}',
                    isSelected: txProvider.filterWalletId == w.id,
                    onTap: () {
                      txProvider.setFilterWallet(w.id);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthNavigator({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth = month.year == DateTime.now().year &&
        month.month == DateTime.now().month;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
            onPressed: onPrev,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Column(
            children: [
              Text(
                DateFormatter.toMonthYear(month),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isCurrentMonth)
                const Text(
                  'Bulan ini',
                  style: TextStyle(fontSize: 10, color: AppColors.primary),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: isCurrentMonth
                  ? AppColors.textMuted
                  : AppColors.textSecondary,
            ),
            onPressed: isCurrentMonth ? null : onNext,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
