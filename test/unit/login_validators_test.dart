import 'package:doodh_khata_mobile/features/auth/presentation/providers/login_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginValidators.phone', () {
    test('rejects empty', () {
      expect(LoginValidators.phone(''), isNotNull);
      expect(LoginValidators.phone(null), isNotNull);
    });

    test('rejects short numbers', () {
      expect(LoginValidators.phone('98765'), isNotNull);
    });

    test('accepts 10-digit mobile', () {
      expect(LoginValidators.phone('9876543210'), isNull);
      expect(LoginValidators.phone('98765 43210'), isNull);
    });
  });

  group('LoginValidators.password', () {
    test('requires min length 8', () {
      expect(LoginValidators.password('123'), isNotNull);
      expect(LoginValidators.password('secret1'), isNotNull);
      expect(LoginValidators.password('secret12'), isNull);
    });
  });
}
