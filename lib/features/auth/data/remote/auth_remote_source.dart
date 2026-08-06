import '../../../../core/api/api_client.dart';
import '../models/auth_dto.dart';

class AuthRemoteSource {
  AuthRemoteSource(this._api);

  final ApiClient _api;

  Future<AuthTokensDto> login(LoginRequest request) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/login',
      data: request.toJson(),
    );
    return AuthTokensDto.fromJson(res.data!);
  }

  Future<AuthTokensDto> register(RegisterRequest request) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/register',
      data: request.toJson(),
    );
    return AuthTokensDto.fromJson(res.data!);
  }

  Future<AuthTokensDto> refresh(String refreshToken) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return AuthTokensDto.fromJson(res.data!);
  }
}
