import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> restoreSession();
  Future<UserEntity> login({required String phone, required String password});
  Future<UserEntity> registerSupplier({
    required String name,
    required String phone,
    required String password,
    String? email,
  });
  Future<bool> refreshSession();
  Future<void> logout();
}
