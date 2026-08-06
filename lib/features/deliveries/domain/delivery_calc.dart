/// Pure helpers for delivery amount maths (unit-tested).
class DeliveryCalc {
  static double amount({
    required double quantityLitres,
    required double ratePerLitre,
  }) {
    if (quantityLitres < 0 || ratePerLitre < 0) {
      throw ArgumentError('Quantity and rate must be non-negative');
    }
    return double.parse((quantityLitres * ratePerLitre).toStringAsFixed(2));
  }

  static double sumAmounts(Iterable<num> amounts) {
    var total = 0.0;
    for (final a in amounts) {
      total += a.toDouble();
    }
    return double.parse(total.toStringAsFixed(2));
  }
}
