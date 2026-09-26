import 'package:doodh_khata_mobile/features/auth/data/models/auth_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auth user json accepts snake_case and missing fields', () {
    final user = AuthUserDto.fromJson({
      'id': 'u1',
      'mobile_number': '919000000099',
    });
    expect(user.id, 'u1');
    expect(user.mobileNumber, '919000000099');
    expect(user.role, 'CUSTOMER');
    expect(user.name, 'User');

    final tokens = AuthTokensDto.fromJson({
      'accessToken': 'a',
      'refreshToken': 'r',
      'user': {'id': 'u1', 'mobile_number': '91', 'name': 'A', 'role': 'CUSTOMER'},
    });
    expect(tokens.user?.id, 'u1');
  });
}
