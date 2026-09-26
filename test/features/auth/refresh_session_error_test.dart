import 'package:doodh_khata_mobile/core/errors/app_exception.dart';
import 'package:doodh_khata_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refresh drops session only on 401/403', () {
    expect(
      shouldDropSessionAfterRefreshError(const AuthException('no', code: '401')),
      isTrue,
    );
    expect(
      shouldDropSessionAfterRefreshError(
        const NetworkException('offline'),
      ),
      isFalse,
    );
    expect(
      shouldDropSessionAfterRefreshError(const AuthException('no', code: '500')),
      isFalse,
    );
  });
}
