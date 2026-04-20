import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/category.dart';
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/shared_widgets.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  TransactionType _type = TransactionType.expense;
  Wallet? _selectedWallet;
  Wallet? _toWallet; // Untuk transfer
  Category? _selectedCategory;
  final _amountCtrl = TextEditingController();
  final _gramCtrl = TextEditingController(); // Untuk beli emas
  final _noteCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isBuyGold = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Gunakan post frame callback agar provider aman diakses
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _loadLastUsed();
    // });
  }

  Future<void> _loadLastUsed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final typeStr = prefs.getString('last_tx_type');
      final walletId = prefs.getInt('last_wallet_id');
      final toWalletId = prefs.getInt('last_to_wallet_id');
      final dateStr = prefs.getString('last_tx_date');

      if (!mounted) return;

      final walletProvider = context.read<WalletProvider>();
      final wallets = walletProvider.wallets;

      setState(() {
        if (typeStr != null) {
          _type = TransactionType.values.firstWhere(
            (t) => t.toString() == typeStr,
            orElse: () => TransactionType.expense,
          );
        }

        if (dateStr != null) {
          final date = DateTime.tryParse(dateStr);
          // Hanya kembalikan tanggal jika valid
          if (date != null) {
            _selectedDate = date;
          }
        }

        if (walletId != null) {
          _selectedWallet = wallets.cast<Wallet?>().firstWhere(
                (w) => w?.id == walletId,
                orElse: () => null,
              );
        }

        if (toWalletId != null) {
          _toWallet = wallets.cast<Wallet?>().firstWhere(
                (w) => w?.id == toWalletId,
                orElse: () => null,
              );
        }
      });
    } catch (e) {
      debugPrint('Error loading last used tx: $e');
    }
  }

  Future<void> _saveCurrentUsed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_tx_type', _type.toString());
      if (_selectedWallet?.id != null) {
        await prefs.setInt('last_wallet_id', _selectedWallet!.id!);
      }
      if (_toWallet?.id != null) {
        await prefs.setInt('last_to_wallet_id', _toWallet!.id!);
      }
      await prefs.setString('last_tx_date', _selectedDate.toIso8601String());
    } catch (e) {
      debugPrint('Error saving last used tx: $e');
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _gramCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _isTransfer => _type == TransactionType.transfer;
  bool get _isGoldWallet => _selectedWallet?.isGold ?? false;
  bool get _showGoldBuyOption =>
      _isTransfer &&
      _toWallet != null &&
      (_toWallet!.isGold || (_selectedWallet?.isGold ?? false));

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final txProvider = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tambah Transaksi'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TYPE SELECTOR
              TypeChipRow(
                selected: _type,
                onChanged: (t) => setState(() {
                  _type = t;
                  _isBuyGold = false;
                  _selectedCategory = null;
                }),
              ),
              const SizedBox(height: 24),
              
              if (walletProvider.wallets.isEmpty)
                const Center(child: Text('Tambah dompet dulu di menu Dompet', style: TextStyle(color: AppColors.textSecondary))),

              // WALLET SELECTOR
              _buildLabel('Dari Dompet'),
              _WalletDropdown(
                wallets: walletProvider.wallets,
                value: _selectedWallet,
                hint: 'Pilih dompet',
                onChanged: (w) => setState(() => _selectedWallet = w),
              ),
              const SizedBox(height: 16),

              // TO WALLET (transfer)
              if (_isTransfer) ...[
                _buildLabel('Ke Dompet'),
                _WalletDropdown(
                  wallets: walletProvider.wallets
                      .where((w) => w.id != _selectedWallet?.id)
                      .toList(),
                  value: _toWallet,
                  hint: 'Pilih dompet tujuan',
                  onChanged: (w) => setState(() {
                    _toWallet = w;
                    _isBuyGold = false;
                  }),
                ),
                const SizedBox(height: 12),

                // BUY GOLD TOGGLE
                if (_toWallet != null && _toWallet!.isGold)
                  _BuyGoldToggle(
                    value: _isBuyGold,
                    onChanged: (v) => setState(() => _isBuyGold = v),
                  ),
                const SizedBox(height: 4),
              ],

              // AMOUNT INPUT
              const SizedBox(height: 8),
              _buildLabel(_isBuyGold ? 'Jumlah Uang (IDR)' : 'Jumlah'),
              AmountInputField(
                controller: _amountCtrl,
                isGold: _isGoldWallet && !_isBuyGold,
                hint: _isBuyGold ? '0' : (_isGoldWallet ? '0.000' : '0'),
              ),

              // GRAM INPUT (hanya saat beli emas)
              if (_isBuyGold) ...[
                const SizedBox(height: 16),
                _buildLabel('Jumlah Emas (gram)'),
                AmountInputField(
                  controller: _gramCtrl,
                  isGold: true,
                  hint: '0.000',
                ),
              ],

              const SizedBox(height: 16),

              // CATEGORY (income/expense only)
              if (!_isTransfer) ...[
                _buildLabel('Kategori (Wajib)'),
                _CategoryDropdown(
                  categories: _type == TransactionType.income
                      ? txProvider.incomeCategories
                      : txProvider.expenseCategories,
                  value: _selectedCategory,
                  onChanged: (c) => setState(() => _selectedCategory = c),
                ),
                const SizedBox(height: 16),
              ],

              // DATE PICKER
              _buildLabel('Tanggal'),
              _DatePickerField(
                date: _selectedDate,
                onChanged: (d) => setState(() => _selectedDate = d),
              ),
              const SizedBox(height: 16),

              // NOTE
              _buildLabel('Catatan (opsional)'),
              TextFormField(
                controller: _noteCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'Tambahkan catatan...'),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _submit(context),
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text('Simpan Transaksi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWallet == null) {
      showErrorSnack(context, 'Pilih dompet terlebih dahulu');
      return;
    }
    if (_isTransfer && _toWallet == null) {
      showErrorSnack(context, 'Pilih dompet tujuan');
      return;
    }
    if (!_isTransfer && _selectedCategory == null) {
      showErrorSnack(context, 'Pilih kategori terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);
    final txProvider = context.read<TransactionProvider>();
    final walletProvider = context.read<WalletProvider>();
    bool success = false;
    String? errMsg;

    try {
      double amount = CurrencyFormatter.parse(
        _amountCtrl.text,
        isGold: _isGoldWallet && !_isBuyGold,
      );

      if (_isBuyGold && _toWallet != null) {
        // Beli emas
        final gram = CurrencyFormatter.parse(_gramCtrl.text, isGold: true);
        if (gram <= 0) throw Exception('Masukkan jumlah gram yang valid.');
        success = await txProvider.buyGold(
          cashWallet: _selectedWallet!,
          goldWallet: _toWallet!,
          idrAmount: amount,
          gramAmount: gram,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          date: _selectedDate,
        );
      } else if (_isTransfer) {
        success = await txProvider.executeTransfer(
          fromWallet: _selectedWallet!,
          toWallet: _toWallet!,
          amount: amount,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          date: _selectedDate,
        );
      } else {
        final tx = Transaction(
          walletId: _selectedWallet!.id!,
          categoryId: _selectedCategory?.id,
          amount: amount,
          type: _type,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          date: _selectedDate,
        );
        success = await txProvider.addTransaction(tx);
      }

      if (success) {
        errMsg = null; // Clear if success
      } else {
        errMsg = txProvider.error;
      }
    } catch (e) {
      errMsg = e.toString().replaceFirst('Exception: ', '');
    } finally {
      setState(() => _isLoading = false);
    }

    if (!mounted) return;
    if (success) {
      walletProvider.loadWallets();
      _saveCurrentUsed(); // Simpan pilihan untuk input berikutnya
      showSuccessSnack(context, 'Transaksi berhasil disimpan!');
      Navigator.pop(context, true);
    } else {
      showErrorSnack(context, errMsg ?? 'Gagal menyimpan transaksi');
    }
  }
}

// ─────────────────────────────────────────────────────────────
// WALLET DROPDOWN
// ─────────────────────────────────────────────────────────────
class _WalletDropdown extends StatelessWidget {
  final List<Wallet> wallets;
  final Wallet? value;
  final String hint;
  final ValueChanged<Wallet?> onChanged;

  const _WalletDropdown({
    required this.wallets,
    this.value,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Wallet>(
      value: wallets.contains(value) ? value : null,
      hint: Text(hint, style: const TextStyle(color: AppColors.textMuted)),
      dropdownColor: AppColors.surfaceAlt,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(),
      items: wallets
          .map(
            (w) => DropdownMenuItem(
              value: w,
              child: Row(
                children: [
                  Text(w.type.emoji),
                  const SizedBox(width: 10),
                  Text(
                    w.name,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    w.isGold
                        ? CurrencyFormatter.formatGram(w.balance)
                        : CurrencyFormatter.formatIDR(w.balance),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (_) => null,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CATEGORY DROPDOWN
// ─────────────────────────────────────────────────────────────
class _CategoryDropdown extends StatelessWidget {
  final List<Category> categories;
  final Category? value;
  final ValueChanged<Category?> onChanged;

  const _CategoryDropdown({
    required this.categories,
    this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Category>(
      value: categories.contains(value) ? value : null,
      hint: const Text('Pilih kategori', style: TextStyle(color: AppColors.textMuted)),
      dropdownColor: AppColors.surfaceAlt,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(),
      items: categories
          .map(
            (c) => DropdownMenuItem(
              value: c,
              child: Text(c.name),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DATE PICKER FIELD
// ─────────────────────────────────────────────────────────────
class _DatePickerField extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerField({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 30)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                surface: AppColors.surfaceAlt,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              DateFormatter.toFull(date),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BUY GOLD TOGGLE
// ─────────────────────────────────────────────────────────────
class _BuyGoldToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BuyGoldToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: value ? AppColors.gold.withOpacity(0.08) : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value ? AppColors.gold.withOpacity(0.4) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          const Text('🪙', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode Beli Emas',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Input berbeda untuk IDR dan gram',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.gold,
          ),
        ],
      ),
    );
  }
}
