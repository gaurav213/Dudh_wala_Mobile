import 'package:doodh_khata_mobile/core/formatters/indian_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatQuantity', () {
    test('omits decimals for whole numbers', () {
      expect(formatQuantity(1), '1');
      expect(formatQuantityString('2.000'), '2');
      expect(formatQuantity(0), '0');
    });

    test('keeps a single decimal place', () {
      expect(formatQuantity(1.5), '1.5');
      expect(formatQuantityString('1.50'), '1.5');
      expect(formatQuantityString('0.500'), '0.5');
      expect(formatQuantity(1.25), '1.3');
    });
  });

  group('formatLitres', () {
    test('adds L suffix', () {
      expect(formatLitresString('1.000'), '1 L');
      expect(formatLitresString('1.500'), '1.5 L');
      expect(formatLitresString('0.500'), '0.5 L');
      expect(formatLitres(1), '1 L');
    });
  });
}
