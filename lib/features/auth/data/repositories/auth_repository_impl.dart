import 'package:uuid/uuid.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_dto.dart';
import '../remote/auth_remote_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AppDatabase db,
    required TokenStorage tokens,
    required AuthRemoteSource remote,
    ApiClient? api,
  })  : _db = db,
        _tokens = tokens,
        _remote = remote;

  final AppDatabase _db;
  final TokenStorage _tokens;
  final AuthRemoteSource _remote;
  static const _uuid = Uuid();

  @override
  Future<UserEntity?> restoreSession() async {
    final has = await _tokens.hasSession();
    if (!has) return null;
    final row = await _db.getAppUser();
    if (row == null) return null;
    return UserEntity.fromMap(row);
  }

  @override
  Future<UserEntity> login({
    required String phone,
    required String password,
  }) async {
    try {
      final dto = await _remote.login(
        LoginRequest(phone: phone, password: password),
      );
      return _persistSession(dto);
    } on NetworkException {
      // Offline demo fallback for local MVP when API unreachable.
      return _localLoginFallback(phone: phone);
    }
  }

  @override
  Future<UserEntity> registerSupplier({
    required String name,
    required String phone,
    required String password,
    String? email,
  }) async {
    try {
      final dto = await _remote.register(
        RegisterRequest(
          name: name,
          phone: phone,
          password: password,
          email: email,
          role: 'supplier',
        ),
      );
      return _persistSession(dto);
    } on NetworkException {
      final user = UserEntity(
        id: _uuid.v4(),
        name: name,
        phone: phone,
        email: email,
        role: UserRole.supplier,
      );
      await _tokens.saveTokens(
        accessToken: 'local-access',
        refreshToken: 'local-refresh',
      );
      await _db.upsertAppUser({
        ...user.toMap(),
        'sync_status': 'LOCAL_ONLY',
      });
      return user;
    }
  }

  Future<UserEntity> _localLoginFallback({required String phone}) async {
    final existing = await _db.getAppUser();
    if (existing != null && existing['phone'] == phone) {
      await _tokens.saveTokens(
        accessToken: 'local-access',
        refreshToken: 'local-refresh',
      );
      return UserEntity.fromMap(existing);
    }
    throw const AuthException(
      'Server unreachable and no local session for this phone',
    );
  }

  Future<UserEntity> _persistSession(AuthTokensDto dto) async {
    await _tokens.saveTokens(
      accessToken: dto.accessToken,
      refreshToken: dto.refreshToken,
    );
    final user = UserEntity(
      id: dto.user.id,
      remoteId: dto.user.id,
      name: dto.user.name,
      phone: dto.user.phone,
      email: dto.user.email,
      role: dto.user.role.toLowerCase() == 'customer'
          ? UserRole.customer
          : UserRole.supplier,
    );
    await _db.upsertAppUser(user.toMap());
    return user;
  }

  @override
  Future<bool> refreshSession() async {
    final refresh = await _tokens.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    if (refresh == 'local-refresh') return true;
    try {
      final dto = await _remote.refresh(refresh);
      await _persistSession(dto);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> logout() async {
    await _tokens.clear();
    await _db.clearUserData();
  }
}
