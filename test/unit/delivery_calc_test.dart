import 'package:doodh_khata_mobile/features/deliveries/domain/delivery_calc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('amount multiplies qty and rate', () {
    expect(
      DeliveryCalc.amount(quantityLitres: 1.5, ratePerLitre: 60),
      90,
    );
  });

  test('sumAmounts rounds to 2 decimals', () {
    expect(DeliveryCalc.sumAmounts([10.125, 20.125]), 30.25);
  });

  test('rejects negatives', () {
    expect(
      () => DeliveryCalc.amount(quantityLitres: -1, ratePerLitre: 10),
      throwsArgumentError,
    );
  });
}
