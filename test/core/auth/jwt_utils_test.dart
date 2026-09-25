import 'dart:convert';

import 'package:doodh_khata_mobile/core/auth/jwt_utils.dart';
import 'package:flutter_test/flutter_test.dart';

String _fakeJwt({required DateTime exp}) {
  final header =
      base64Url.encode(utf8.encode('{"alg":"none"}')).replaceAll('=', '');
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'exp': exp.toUtc().millisecondsSinceEpoch ~/ 1000,
          }),
        ),
      )
      .replaceAll('=', '');
  return '$header.$payload.sig';
}

void main() {
  group('JwtUtils.isExpiredOrExpiring', () {
    test('treats null/empty as expired', () {
      expect(JwtUtils.isExpiredOrExpiring(null), isTrue);
      expect(JwtUtils.isExpiredOrExpiring(''), isTrue);
    });

    test('local-access never expires', () {
      expect(JwtUtils.isExpiredOrExpiring('local-access'), isFalse);
    });

    test('future token is valid', () {
      final token =
          _fakeJwt(exp: DateTime.now().toUtc().add(const Duration(hours: 1)));
      expect(JwtUtils.isExpiredOrExpiring(token), isFalse);
    });

    test('past token is expired', () {
      final token = _fakeJwt(
          exp: DateTime.now().toUtc().subtract(const Duration(minutes: 1)));
      expect(JwtUtils.isExpiredOrExpiring(token), isTrue);
    });

    test('token within skew window is treated as expiring', () {
      final token = _fakeJwt(
          exp: DateTime.now().toUtc().add(const Duration(seconds: 30)));
      expect(
        JwtUtils.isExpiredOrExpiring(token, skew: const Duration(seconds: 60)),
        isTrue,
      );
    });
  });
}
