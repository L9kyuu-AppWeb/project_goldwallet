import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../models/wallet.dart';
import '../providers/wallet_provider.dart';
import 'package:provider/provider.dart';

class WalletCard extends StatelessWidget {
  final Wallet wallet;
  final bool isSelected;
  final VoidCallback? onTap;

  const WalletCard({
    super.key,
    required this.wallet,
    this.isSelected = false,
    this.onTap,
  });

  Color get _accentColor {
    switch (wallet.type) {
      case WalletType.cash: return AppColors.cash;
      case WalletType.bank: return AppColors.bank;
      case WalletType.eWallet: return AppColors.eWallet;
      case WalletType.gold: return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final valueIDR = walletProvider.walletValueIDR(wallet);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? _accentColor.withOpacity(0.1)
              : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _accentColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(wallet.type.emoji, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                if (wallet.isMain)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'UTAMA',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              wallet.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (wallet.isGold) ...[
              Text(
                CurrencyFormatter.formatGram(wallet.balance),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _accentColor,
                ),
              ),
              Text(
                '≈ ${CurrencyFormatter.formatCompact(valueIDR)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ] else ...[
              Text(
                CurrencyFormatter.formatIDR(wallet.balance),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _accentColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WALLET LIST TILE (untuk halaman dompet)
// ─────────────────────────────────────────────────────────────
class WalletListTile extends StatelessWidget {
  final Wallet wallet;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const WalletListTile({
    super.key,
    required this.wallet,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  Color get _accentColor {
    switch (wallet.type) {
      case WalletType.cash: return AppColors.cash;
      case WalletType.bank: return AppColors.bank;
      case WalletType.eWallet: return AppColors.eWallet;
      case WalletType.gold: return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(wallet.type.emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                wallet.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (wallet.isMain)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Text(
                  'UTAMA',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          wallet.type.label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (wallet.isGold) ...[
                  Text(
                    CurrencyFormatter.formatGram(wallet.balance),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _accentColor,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '≈ ${CurrencyFormatter.formatCompact(walletProvider.walletValueIDR(wallet))}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ] else ...[
                  Text(
                    CurrencyFormatter.formatIDR(wallet.balance),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _accentColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
            if (!wallet.isMain) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 18),
                color: AppColors.surfaceAlt,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Text('Edit', style: TextStyle(color: AppColors.textPrimary)),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 16, color: AppColors.expense),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(color: AppColors.expense)),
                    ]),
                  ),
                ],
                onSelected: (v) {
                  if (v == 'edit') onEdit?.call();
                  if (v == 'delete') onDelete?.call();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
