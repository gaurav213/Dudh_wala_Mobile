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
