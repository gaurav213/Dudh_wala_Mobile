import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

final _inr = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

final _date = DateFormat('dd MMM yyyy');
final _dateTime = DateFormat('dd MMM yyyy, hh:mm a');

String formatRupees(num amount) => _inr.format(amount);

String formatRupeesDecimal(Decimal amount) => _inr.format(amount.toDouble());

String formatLitres(num litres) {
  final v = litres.toDouble();
  if (v == v.roundToDouble()) {
    return '${v.toInt()} L';
  }
  return '${v.toStringAsFixed(2)} L';
}

String formatLitresDecimal(Decimal litres) => formatLitres(litres.toDouble());

String formatDate(DateTime date) => _date.format(date.toLocal());

String formatDateTime(DateTime date) => _dateTime.format(date.toLocal());

String formatPhoneIn(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) {
    return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
  }
  return phone;
}


String formatLitresString(Object? value) {
  if (value == null) return formatLitres(0);
  if (value is num) return formatLitres(value);
  final n = num.tryParse(value.toString().trim());
  return formatLitres(n ?? 0);
}

String formatQuantityString(Object? value) {
  if (value == null) return '0';
  if (value is num) {
    final v = value.toDouble();
    if (v == v.roundToDouble()) return '${v.toInt()}';
    return v.toStringAsFixed(2);
  }
  final raw = value.toString().trim();
  final n = num.tryParse(raw);
  if (n == null) return raw;
  final v = n.toDouble();
  if (v == v.roundToDouble()) return '${v.toInt()}';
  return v.toStringAsFixed(2);
}

String formatMonthYear(DateTime date) =>
    DateFormat('MMM yyyy').format(date.toLocal());

String formatRelativeTime(DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatDate(local);
}
