import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme.dart';
import 'providers/wallet_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF111114),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const GoldWalletApp());
}

class GoldWalletApp extends StatelessWidget {
  const GoldWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        title: 'Gold Wallet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const HomeScreen(),
      ),
    );
  }
}
