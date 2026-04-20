import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../core/constants.dart';
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/database_helper.dart';
import '../widgets/wallet_widgets.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/shared_widgets.dart';
import 'add_transaction_screen.dart';
import 'wallets_screen.dart';
import 'transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().loadWallets();
      context.read<TransactionProvider>().loadAll();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: [
        _DashboardTab(
          onSeeAllWallets: () => setState(() => _selectedIndex = 2),
          onSeeAllTransactions: () => setState(() => _selectedIndex = 1),
        ),
        const TransactionsScreen(),
        const WalletsScreen(),
      ]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Transaksi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Dompet',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
          if (result == true && mounted) {
            context.read<WalletProvider>().loadWallets();
            context.read<TransactionProvider>().loadTransactions();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        elevation: 0,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DASHBOARD TAB
// ─────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final VoidCallback onSeeAllWallets;
  final VoidCallback onSeeAllTransactions;

  const _DashboardTab({
    required this.onSeeAllWallets,
    required this.onSeeAllTransactions,
  });

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await walletProvider.loadWallets();
          await txProvider.loadTransactions();
        },
        child: CustomScrollView(
          slivers: [
            // APP BAR
            SliverAppBar(
              expandedHeight: 0,
              pinned: true,
              backgroundColor: AppColors.background,
              title: const Row(
                children: [
                  Text(
                    '🪙 ',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    'Gold',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Wallet',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.settings_outlined),
                  color: AppColors.surfaceAlt,
                  offset: const Offset(0, 40),
                  onSelected: (val) {
                    if (val == 'gold_price') {
                      _showGoldPriceDialog(context, walletProvider);
                    } else if (val == 'backup') {
                      _exportBackup(context);
                    } else if (val == 'restore') {
                      _importBackup(context);
                    } else if (val == 'reset') {
                      _handleReset(context);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'gold_price', child: Text('🪙 Atur Harga Emas')),
                    const PopupMenuItem(value: 'backup', child: Text('📤 Export Data')),
                    const PopupMenuItem(value: 'restore', child: Text('📥 Import Data')),
                    const PopupMenuItem(
                      value: 'reset',
                      child: Text('🧹 Reset Data', style: TextStyle(color: AppColors.expense)),
                    ),
                  ],
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOTAL BALANCE CARD
                    _TotalBalanceCard(
                      totalIDR: walletProvider.totalBalanceIDR,
                      totalGold: walletProvider.totalGoldGram,
                      goldPrice: walletProvider.goldPricePerGram,
                    ),
                    const SizedBox(height: 24),

                    // SUMMARY CARDS
                    FutureBuilder<Map<String, double>>(
                      future: txProvider.getMonthlySummary(),
                      builder: (ctx, snap) {
                        final income = snap.data?['income'] ?? 0;
                        final expense = snap.data?['expense'] ?? 0;
                        return Row(
                          children: [
                            Expanded(
                              child: _SummaryCard(
                                label: 'Pemasukan',
                                amount: income,
                                color: AppColors.income,
                                icon: '↑',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryCard(
                                label: 'Pengeluaran',
                                amount: expense,
                                color: AppColors.expense,
                                icon: '↓',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // WALLETS
                    SectionHeader(
                      title: 'Dompet Saya',
                      actionLabel: 'Lihat Semua',
                      onAction: onSeeAllWallets,
                    ),
                    const SizedBox(height: 12),
                    walletProvider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        : SizedBox(
                            height: 160,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              scrollDirection: Axis.horizontal,
                              itemCount: walletProvider.wallets.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (_, i) => WalletCard(
                                wallet: walletProvider.wallets[i],
                              ),
                            ),
                          ),
                    const SizedBox(height: 28),

                    // RECENT TRANSACTIONS
                    SectionHeader(
                      title: 'Transaksi Terkini',
                      actionLabel: 'Lihat Semua',
                      onAction: onSeeAllTransactions,
                    ),
                    const SizedBox(height: 12),
                    txProvider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        : txProvider.transactions.isEmpty
                            ? const EmptyState(
                                emoji: '📋',
                                title: 'Belum ada transaksi',
                                subtitle: 'Mulai catat pemasukan dan pengeluaranmu',
                              )
                            : Column(
                                children: txProvider.transactions
                                    .take(5)
                                    .map(
                                      (tx) => TransactionTile(
                                        transaction: tx,
                                        onDelete: () async {
                                          final ok = await txProvider.deleteTransaction(tx);
                                          if (ok && context.mounted) {
                                            walletProvider.loadWallets();
                                            showSuccessSnack(context, 'Transaksi dihapus');
                                          } else if (context.mounted && txProvider.error != null) {
                                            showErrorSnack(context, txProvider.error!);
                                            txProvider.clearError();
                                          }
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoldPriceDialog(BuildContext context, WalletProvider provider) {
    final ctrl = TextEditingController(
      text: provider.goldPricePerGram.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          '⚙️ Harga Emas / Gram',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Atur harga emas per gram (IDR) untuk kalkulasi nilai portofolio.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Harga per gram',
                prefixText: 'Rp ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(ctrl.text);
              if (price != null && price > 0) {
                provider.updateGoldPrice(price);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    final dbPath = p.join(await getDatabasesPath(), AppConstants.dbName);
    final file = File(dbPath);
    if (!await file.exists()) {
      showErrorSnack(context, 'Data backup tidak ditemukan.');
      return;
    }
    await Share.shareXFiles([XFile(dbPath)], text: 'Backup Data Keuanganku');
  }

  Future<void> _importBackup(BuildContext context) async {
    final result = await FilePicker.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      final sourceFile = File(result.files.single.path!);
      final dbPath = p.join(await getDatabasesPath(), AppConstants.dbName);
      
      try {
        await sourceFile.copy(dbPath);
        
        final walFile = File('$dbPath-wal');
        final shmFile = File('$dbPath-shm');
        if (await walFile.exists()) await walFile.delete();
        if (await shmFile.exists()) await shmFile.delete();
        
        if (context.mounted) {
          showSuccessSnack(context, 'Data berhasil direstore!');
          context.read<WalletProvider>().loadWallets();
          context.read<TransactionProvider>().loadAll();
        }
      } catch (e) {
        if (context.mounted) {
          showErrorSnack(context, 'Gagal restore: $e');
        }
      }
    }
  }

  Future<void> _handleReset(BuildContext context) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Hapus Semua Data?',
      content: 'Tindakan ini akan menghapus semua dompet, kategori, dan transaksi Anda secara permanen. Data tidak bisa dikembalikan.',
      confirmLabel: 'Ya, Reset',
      confirmColor: AppColors.expense,
    );

    if (confirm && context.mounted) {
      try {
        await DatabaseHelper.instance.resetDatabase();
        if (context.mounted) {
          context.read<WalletProvider>().loadWallets();
          context.read<TransactionProvider>().loadAll();
          showSuccessSnack(context, 'Data berhasil dikosongkan!');
        }
      } catch (e) {
        if (context.mounted) {
          showErrorSnack(context, 'Gagal reset data: $e');
        }
      }
    }
  }
}


// ─────────────────────────────────────────────────────────────
// TOTAL BALANCE CARD
// ─────────────────────────────────────────────────────────────
class _TotalBalanceCard extends StatelessWidget {
  final double totalIDR;
  final double totalGold;
  final double goldPrice;

  const _TotalBalanceCard({
    required this.totalIDR,
    required this.totalGold,
    required this.goldPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.surfaceAlt,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Aset',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatIDR(totalIDR),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1,
              fontFamily: 'Syne',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (totalGold > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Text(
                '🪙 ${CurrencyFormatter.formatGram(totalGold)} emas',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUMMARY CARD (income/expense)
// ─────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            CurrencyFormatter.formatCompact(amount),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
