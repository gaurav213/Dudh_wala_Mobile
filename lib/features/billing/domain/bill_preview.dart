import '../../deliveries/domain/delivery_calc.dart';

class BillLinePreview {
  const BillLinePreview({
    required this.deliveryId,
    required this.date,
    required this.description,
    required this.quantityLitres,
    required this.ratePerLitre,
    required this.amount,
  });

  final String deliveryId;
  final DateTime date;
  final String description;
  final double quantityLitres;
  final double ratePerLitre;
  final double amount;
}

class BillPreview {
  const BillPreview({
    required this.customerId,
    required this.periodStart,
    required this.periodEnd,
    required this.lines,
    required this.subtotal,
    this.adjustments = 0,
  });

  final String customerId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<BillLinePreview> lines;
  final double subtotal;
  final double adjustments;

  double get total => DeliveryCalc.sumAmounts([subtotal, adjustments]);

  static BillPreview fromDeliveries({
    required String customerId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Map<String, Object?>> deliveries,
    double adjustments = 0,
  }) {
    final lines = <BillLinePreview>[];
    for (final d in deliveries) {
      if (d['status'] == 'skipped') continue;
      final qty = (d['quantity_litres'] as num).toDouble();
      final rate = (d['rate_per_litre'] as num).toDouble();
      final amount = (d['amount'] as num?)?.toDouble() ??
          DeliveryCalc.amount(quantityLitres: qty, ratePerLitre: rate);
      lines.add(
        BillLinePreview(
          deliveryId: d['id'] as String,
          date: d['delivery_date'] as DateTime,
          description: 'Milk · ${d['slot'] ?? 'morning'}',
          quantityLitres: qty,
          ratePerLitre: rate,
          amount: amount,
        ),
      );
    }
    final subtotal = DeliveryCalc.sumAmounts(lines.map((l) => l.amount));
    return BillPreview(
      customerId: customerId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      lines: lines,
      subtotal: subtotal,
      adjustments: adjustments,
    );
  }
}
