import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> restoreSession();

  /// Local user row only — no network. Used when splash refresh times out.
  Future<UserEntity?> restoreCachedUser();
  Future<UserEntity> login({required String phone, required String password});
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
  });
  Future<UserEntity> registerCustomer({
    required String name,
    required String phone,
    required String password,
  });
  Future<bool> refreshSession();

  /// True when a refresh (or access) token is still stored locally.
  Future<bool> hasSession();

  /// Revoke refresh token on server (best-effort), then clear local session.
  Future<void> logout();

  /// Clear local tokens/session without calling the server (refresh failed / revoked).
  Future<void> clearLocalSession();

  Future<UserEntity> updateProfile({String? name, String? email});
  Future<UserEntity> uploadAvatar(String filePath);

  /// Permanently closes the account on the server and clears local session.
  Future<void> deleteAccount();
}
