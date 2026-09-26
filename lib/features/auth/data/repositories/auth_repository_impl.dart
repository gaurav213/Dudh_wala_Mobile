import 'package:uuid/uuid.dart';

import '../../../../core/auth/jwt_utils.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/environment/app_environment.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_dto.dart';
import '../remote/auth_remote_source.dart';

/// Only a rejected refresh token should wipe the session.
bool shouldDropSessionAfterRefreshError(Object error) {
  return error is AuthException &&
      (error.code == '401' || error.code == '403');
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AppDatabase db,
    required TokenStorage tokens,
    required AuthRemoteSource remote,
  })  : _db = db,
        _tokens = tokens,
        _remote = remote;

  final AppDatabase _db;
  final TokenStorage _tokens;
  final AuthRemoteSource _remote;
  static const _uuid = Uuid();

  bool get _allowOfflineDemo => AppEnvironment.current.isDev;

  String _normalizeMobile(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return '91$digits';
    return digits;
  }

  UserEntity _userFromDto(AuthUserDto profile) => UserEntity(
        id: profile.id,
        remoteId: profile.id,
        name: profile.name,
        phone: profile.mobileNumber,
        email: profile.email,
        avatarUrl: profile.avatarUrl,
        role: UserEntity.roleFromApi(profile.role),
      );

  @override
  Future<UserEntity?> restoreSession() async {
    final has = await _tokens.hasSession();
    if (!has) return null;

    final refresh = await _tokens.readRefreshToken();
    final access = await _tokens.readAccessToken();

    // Access may be expired while refresh is still valid — renew quietly.
    if (refresh != null &&
        refresh.isNotEmpty &&
        refresh != 'local-refresh' &&
        JwtUtils.isExpiredOrExpiring(access)) {
      final ok = await refreshSession();
      // Network / timeout must not look like logout — tokens are still valid.
      if (!ok && !await _tokens.hasSession()) return null;
    }

    final cached = await restoreCachedUser();
    if (cached != null) return cached;
    return _profileFromTokens();
  }

  @override
  Future<UserEntity?> restoreCachedUser() async {
    if (!await _tokens.hasSession()) return null;
    final row = await _db.getAppUser();
    return row == null ? null : UserEntity.fromMap(row);
  }

  Future<UserEntity?> _profileFromTokens() async {

    // Tokens exist but local user row missing (e.g. reinstall kept keychain).
    try {
      final profile = await _remote.profile();
      final user = _userFromDto(profile);
      await _db.upsertAppUser(user.toMap());
      return user;
    } on AuthException catch (e) {
      if (shouldDropSessionAfterRefreshError(e)) await _tokens.clear();
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserEntity> login({
    required String phone,
    required String password,
  }) async {
    final mobileNumber = _normalizeMobile(phone);
    try {
      final dto = await _remote.login(
        LoginRequest(mobileNumber: mobileNumber, password: password),
      );
      return _persistSession(dto);
    } on NetworkException {
      if (!_allowOfflineDemo) rethrow;
      return _localLoginFallback(phone: mobileNumber);
    }
  }

  @override
  Future<UserEntity> registerFarmOwner({
    required String name,
    required String phone,
    required String password,
    required String farmName,
    required String addressLine1,
    required String area,
    required String city,
    required String state,
    required String postalCode,
    String? businessName,
    String? email,
  }) async {
    final mobileNumber = _normalizeMobile(phone);
    try {
      final dto = await _remote.registerFarmOwner(
        RegisterFarmOwnerRequest(
          name: name,
          mobileNumber: mobileNumber,
          password: password,
          farmName: farmName,
          addressLine1: addressLine1,
          area: area,
          city: city,
          state: state,
          postalCode: postalCode,
          businessName: businessName,
          email: email,
        ),
      );
      return _persistSession(dto);
    } on NetworkException {
      if (!_allowOfflineDemo) rethrow;
      final user = UserEntity(
        id: _uuid.v4(),
        name: name,
        phone: mobileNumber,
        email: email,
        role: UserRole.farmOwner,
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

  @override
  Future<UserEntity> registerCustomer({
    required String name,
    required String phone,
    required String password,
  }) async {
    final mobileNumber = _normalizeMobile(phone);
    try {
      final dto = await _remote.registerCustomer(
        RegisterCustomerRequest(
          name: name,
          mobileNumber: mobileNumber,
          password: password,
        ),
      );
      return _persistSession(dto);
    } on NetworkException {
      if (!_allowOfflineDemo) rethrow;
      final user = UserEntity(
        id: _uuid.v4(),
        name: name,
        phone: mobileNumber,
        role: UserRole.customer,
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
    final apiUser = dto.user;
    if (apiUser == null) {
      throw const AuthException('Auth response missing user');
    }
    final user = _userFromDto(apiUser);
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
      await _tokens.saveTokens(
        accessToken: dto.accessToken,
        refreshToken: dto.refreshToken,
      );
      if (dto.user != null) {
        await _db.upsertAppUser(_userFromDto(dto.user!).toMap());
      }
      return true;
    } on AuthException catch (e) {
      if (shouldDropSessionAfterRefreshError(e)) {
        await _tokens.clear();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasSession() => _tokens.hasSession();

  @override
  Future<void> logout() async {
    final refresh = await _tokens.readRefreshToken();
    if (refresh != null &&
        refresh.isNotEmpty &&
        refresh != 'local-refresh') {
      try {
        await _remote.logout(refresh);
      } catch (_) {
        // Best-effort revoke; always clear local session.
      }
    }
    await clearLocalSession();
  }

  @override
  Future<void> clearLocalSession() async {
    await _tokens.clear();
    await _db.clearUserData();
  }

  @override
  Future<UserEntity> updateProfile({String? name, String? email}) async {
    final profile = await _remote.updateProfile(name: name, email: email);
    final user = _userFromDto(profile);
    await _db.upsertAppUser(user.toMap());
    return user;
  }

  @override
  Future<UserEntity> uploadAvatar(String filePath) async {
    final profile = await _remote.uploadAvatar(filePath);
    final user = _userFromDto(profile);
    await _db.upsertAppUser(user.toMap());
    return user;
  }

  @override
  Future<void> deleteAccount() async {
    await _remote.deleteAccount();
    await clearLocalSession();
  }
}
