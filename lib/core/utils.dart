import 'dart:math';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _idr = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static final _gram = NumberFormat('#,##0.####', 'id_ID');

  static String formatIDR(double amount) => _idr.format(amount);

  static String formatGram(double gram) => '${_gram.format(gram)} gr';

  static String formatCompact(double amount) {
    if (amount >= 1000000000) return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}M';
    if (amount >= 1000000) return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    if (amount >= 1000) return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    return formatIDR(amount);
  }

  static double parse(String value, {bool isGold = false}) {
    if (value.isEmpty) return 0;
    if (isGold) {
      // For gold, we expect standard decimal format (e.g., 1.234)
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    } else {
      // For IDR, remove thousands separators (dots)
      final clean = value.replaceAll('.', '');
      return double.tryParse(clean) ?? 0;
    }
  }
}

class DateFormatter {
  static final _full = DateFormat('dd MMMM yyyy', 'id_ID');
  static final _short = DateFormat('dd MMM', 'id_ID');
  static final _withTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final _monthYear = DateFormat('MMMM yyyy', 'id_ID');
  static final _iso = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  static String toFull(DateTime dt) => _full.format(dt);
  static String toShort(DateTime dt) => _short.format(dt);
  static String toWithTime(DateTime dt) => _withTime.format(dt);
  static String toMonthYear(DateTime dt) => _monthYear.format(dt);
  static String toISO(DateTime dt) => _iso.format(dt);

  static DateTime fromISO(String s) {
    try {
      return _iso.parse(s);
    } catch (_) {
      return DateTime.tryParse(s) ?? DateTime.now();
    }
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class IdGenerator {
  static final _random = Random();

  static String transferId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = _random.nextInt(99999).toString().padLeft(5, '0');
    return 'TRF_${ts}_$rand';
  }

  static String generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = _random.nextInt(9999).toString().padLeft(4, '0');
    return '${ts}_$rand';
  }
}

class GoldCalculator {
  /// Harga emas default per gram dalam IDR (bisa diupdate dari API)
  static const double defaultPricePerGram = 1050000;

  static double toIDR(double gram, double pricePerGram) => gram * pricePerGram;
  static double toGram(double idr, double pricePerGram) =>
      pricePerGram > 0 ? idr / pricePerGram : 0;
}
