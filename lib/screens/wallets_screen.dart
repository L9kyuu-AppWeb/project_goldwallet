import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../models/wallet.dart';
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/wallet_widgets.dart';
import '../widgets/shared_widgets.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dompet Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddWalletSheet(context),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : provider.wallets.isEmpty
              ? const EmptyState(
                  emoji: '👛',
                  title: 'Belum ada dompet',
                  subtitle: 'Tambahkan dompet untuk mulai mencatat',
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => provider.loadWallets(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                    children: [
                      // TOTAL
                      _TotalPortfolioCard(provider: provider),
                      const SizedBox(height: 24),

                      // GOLD WALLETS
                      if (provider.goldWallets.isNotEmpty) ...[
                        const SectionHeader(title: '🪙 Dompet Emas'),
                        const SizedBox(height: 10),
                        ...provider.goldWallets.map(
                          (w) => WalletListTile(
                            wallet: w,
                            onEdit: () => _showEditWalletSheet(context, w),
                            onDelete: () => _deleteWallet(context, w),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // NON-GOLD WALLETS
                      const SectionHeader(title: '💼 Dompet Lainnya'),
                      const SizedBox(height: 10),
                      ...provider.nonGoldWallets.map(
                        (w) => WalletListTile(
                          wallet: w,
                          onEdit: () => _showEditWalletSheet(context, w),
                          onDelete: () => _deleteWallet(context, w),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _deleteWallet(BuildContext context, Wallet wallet) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Hapus "${wallet.name}"?',
      content:
          'Semua transaksi di dompet ini akan ikut terhapus. Tindakan ini tidak dapat dibatalkan.',
    );
    if (!confirm || !context.mounted) return;

    final ok = await context.read<WalletProvider>().deleteWallet(wallet);
    if (context.mounted) {
      if (ok) {
        context.read<TransactionProvider>().loadTransactions();
        showSuccessSnack(context, '${wallet.name} berhasil dihapus');
      } else {
        final err = context.read<WalletProvider>().error ?? 'Gagal menghapus dompet';
        showErrorSnack(context, err);
        context.read<WalletProvider>().clearError();
      }
    }
  }

  void _showAddWalletSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _WalletForm(),
    );
  }

  void _showEditWalletSheet(BuildContext context, Wallet wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _WalletForm(existingWallet: wallet),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOTAL PORTFOLIO CARD
// ─────────────────────────────────────────────────────────────
class _TotalPortfolioCard extends StatelessWidget {
  final WalletProvider provider;

  const _TotalPortfolioCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.12),
            AppColors.surfaceAlt,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Portofolio',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.formatIDR(provider.totalBalanceIDR),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Syne',
                    letterSpacing: -0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (provider.totalGoldGram > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '🪙 Total Emas',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatGram(provider.totalGoldGram),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WALLET FORM (Add/Edit)
// ─────────────────────────────────────────────────────────────
class _WalletForm extends StatefulWidget {
  final Wallet? existingWallet;

  const _WalletForm({this.existingWallet});

  @override
  State<_WalletForm> createState() => _WalletFormState();
}

class _WalletFormState extends State<_WalletForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late WalletType _type;
  bool _isLoading = false;

  bool get _isEdit => widget.existingWallet != null;
  bool get _isGold => _type == WalletType.gold;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingWallet?.name ?? '');
    _balanceCtrl = TextEditingController(
      text: widget.existingWallet?.balance.toString() ?? '',
    );
    _type = widget.existingWallet?.type ?? WalletType.cash;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit ? 'Edit Dompet' : 'Tambah Dompet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Syne',
              ),
            ),
            const SizedBox(height: 20),

            // WALLET TYPE SELECTOR
            if (!_isEdit) ...[
              const Text(
                'Tipe Dompet',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _WalletTypeSelector(
                selected: _type,
                onChanged: (t) => setState(() => _type = t),
              ),
              const SizedBox(height: 16),
            ],

            // NAME
            const Text(
              'Nama Dompet',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Contoh: ${_type.label} BCA',
                prefixText: '${_type.emoji} ',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Nama tidak boleh kosong';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // SALDO AWAL
            Text(
              _isEdit
                  ? 'Saldo Saat Ini${_isGold ? ' (gram)' : ''}'
                  : 'Saldo Awal${_isGold ? ' (gram)' : ''}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            AmountInputField(
              controller: _balanceCtrl,
              isGold: _isGold,
              hint: _isGold ? '0.000' : '0',
            ),
            const SizedBox(height: 24),

            // SUBMIT
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Dompet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final provider = context.read<WalletProvider>();
    final balance = CurrencyFormatter.parse(_balanceCtrl.text, isGold: _isGold);
    bool ok = false;

    if (_isEdit) {
      ok = await provider.updateWallet(
        widget.existingWallet!.copyWith(name: _nameCtrl.text.trim()),
      );
    } else {
      ok = await provider.addWallet(
        Wallet(
          name: _nameCtrl.text.trim(),
          type: _type,
          balance: balance,
          createdAt: DateTime.now(),
        ),
      );
    }

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
      showSuccessSnack(
        context,
        _isEdit ? 'Dompet berhasil diperbarui' : 'Dompet berhasil ditambahkan',
      );
    } else {
      final err = provider.error ?? 'Gagal menyimpan dompet';
      showErrorSnack(context, err);
      provider.clearError();
    }
  }
}

// ─────────────────────────────────────────────────────────────
// WALLET TYPE SELECTOR
// ─────────────────────────────────────────────────────────────
class _WalletTypeSelector extends StatelessWidget {
  final WalletType selected;
  final ValueChanged<WalletType> onChanged;

  const _WalletTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: WalletType.values.map((type) {
        final isSelected = type == selected;
        final color = type == WalletType.gold
            ? AppColors.gold
            : type == WalletType.cash
                ? AppColors.cash
                : type == WalletType.bank
                    ? AppColors.bank
                    : AppColors.eWallet;

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.12) : AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(type.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 3),
                  Text(
                    type.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
