import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/auth_dto.dart';

/// Auth endpoints use a dedicated [ApiClient] that never re-enters refresh.
class AuthRemoteSource {
  AuthRemoteSource(this._api);

  final ApiClient _api;

  static const _authExtra = {
    kSkipAuthHeader: true,
    kSkipAuthRefresh: true,
  };

  Future<AuthTokensDto> login(LoginRequest request) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/login',
      data: request.toJson(),
      extra: _authExtra,
    );
    return AuthTokensDto.fromJson(_unwrap(res));
  }

  Future<AuthTokensDto> registerFarmOwner(
      RegisterFarmOwnerRequest request) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/register/farm-owner',
      data: request.toJson(),
      extra: _authExtra,
    );
    return AuthTokensDto.fromJson(_unwrap(res));
  }

  Future<AuthTokensDto> registerCustomer(
      RegisterCustomerRequest request) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/register/customer',
      data: request.toJson(),
      extra: _authExtra,
    );
    return AuthTokensDto.fromJson(_unwrap(res));
  }

  Future<AuthTokensDto> refresh(String refreshToken) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
      extra: _authExtra,
    );
    return AuthTokensDto.fromJson(_unwrap(res));
  }

  Future<void> logout(String refreshToken) async {
    await _api.post<Map<String, dynamic>>(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
      extra: _authExtra,
    );
  }

  Future<AuthUserDto> profile() async {
    final res = await _api.get<Map<String, dynamic>>('/auth/profile');
    final data = _unwrap(res);
    final user = data['user'];
    if (user is Map<String, dynamic>) {
      return AuthUserDto.fromJson(user);
    }
    throw const AuthException('Profile response missing user');
  }

  Future<AuthUserDto> updateProfile({String? name, String? email}) async {
    final res = await _api.patch<Map<String, dynamic>>(
      '/auth/profile',
      data: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
      },
    );
    final data = _unwrap(res);
    final user = data['user'];
    if (user is Map<String, dynamic>) {
      return AuthUserDto.fromJson(user);
    }
    throw const AuthException('Profile update response missing user');
  }

  Future<AuthUserDto> uploadAvatar(String filePath) async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath),
    });
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/profile/avatar',
      data: form,
    );
    final data = _unwrap(res);
    final user = data['user'];
    if (user is Map<String, dynamic>) {
      return AuthUserDto.fromJson(user);
    }
    throw const AuthException('Avatar upload response missing user');
  }

  Future<void> deleteAccount() async {
    await _api.delete<Map<String, dynamic>>('/auth/account');
  }

  Map<String, dynamic> _unwrap(Response<Map<String, dynamic>> res) {
    final body = res.data;
    if (body == null) {
      throw const AuthException('Empty auth response');
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return body;
  }
}
