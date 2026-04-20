import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../models/wallet.dart';

// ─────────────────────────────────────────────────────────────
// APP CARD
// ─────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor ?? AppColors.border,
            width: 1,
          ),
        ),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButton;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onButton,
                child: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CONFIRM DIALOG
// ─────────────────────────────────────────────────────────────
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmLabel = 'Hapus',
  Color confirmColor = AppColors.expense,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceAlt,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            content,
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
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;
}

// ─────────────────────────────────────────────────────────────
// WALLET TYPE BADGE
// ─────────────────────────────────────────────────────────────
class WalletTypeBadge extends StatelessWidget {
  final WalletType type;

  const WalletTypeBadge({super.key, required this.type});

  Color get _color {
    switch (type) {
      case WalletType.cash: return AppColors.cash;
      case WalletType.bank: return AppColors.bank;
      case WalletType.eWallet: return AppColors.eWallet;
      case WalletType.gold: return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        type.label,
        style: TextStyle(
          fontSize: 10,
          color: _color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AMOUNT INPUT FIELD
// ─────────────────────────────────────────────────────────────
class AmountInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool isGold;
  final String? label;
  final String? hint;
  final bool readOnly;

  const AmountInputField({
    super.key,
    required this.controller,
    this.isGold = false,
    this.label,
    this.hint,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: isGold
          ? const TextInputType.numberWithOptions(decimal: true)
          : const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: isGold
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : [CurrencyInputFormatter()],
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint ?? (isGold ? '0.000' : '0'),
        prefixText: isGold ? '' : 'Rp ',
        prefixStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        suffixText: isGold ? 'gram' : null,
        suffixStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Jumlah tidak boleh kosong';
        final n = CurrencyFormatter.parse(v, isGold: isGold);
        if (n < 0) return 'Masukkan jumlah yang valid';
        return null;
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TRANSACTION TYPE CHIP ROW
// ─────────────────────────────────────────────────────────────
class TypeChipRow extends StatelessWidget {
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  const TypeChipRow({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TransactionType.values.map((type) {
        final isSelected = type == selected;
        final color = type == TransactionType.income
            ? AppColors.income
            : type == TransactionType.expense
                ? AppColors.expense
                : AppColors.transfer;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                type.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SNACKBAR HELPERS
// ─────────────────────────────────────────────────────────────
void showSuccessSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
      backgroundColor: AppColors.income,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

void showErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
      backgroundColor: AppColors.expense,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 6),
      action: SnackBarAction(
        label: 'TUTUP',
        textColor: Colors.white,
        onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final intValue = int.tryParse(newValue.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (intValue == null) return newValue;
    final newText = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(intValue).trim();
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
