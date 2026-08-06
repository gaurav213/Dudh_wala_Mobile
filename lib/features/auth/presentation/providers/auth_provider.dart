import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../data/remote/auth_remote_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final tokens = ref.watch(tokenStorageProvider);
  final db = ref.watch(appDatabaseProvider);
  // Lightweight Dio for auth refresh bootstrap (no circular auth refresh).
  final api = ApiClient(
    tokenStorage: tokens,
    onRefresh: () async => false,
  );
  return AuthRepositoryImpl(
    db: db,
    tokens: tokens,
    remote: AuthRemoteSource(api),
  );
});

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.initialized = false,
  });

  final UserEntity? user;
  final bool isLoading;
  final String? error;
  final bool initialized;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? error,
    bool? initialized,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      initialized: initialized ?? this.initialized,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState());

  final AuthRepository _repo;

  Future<void> bootstrap() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repo.restoreSession();
      state = AuthState(user: user, initialized: true);
    } catch (e) {
      state = AuthState(initialized: true, error: e.toString());
    }
  }

  Future<void> login({required String phone, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.login(phone: phone, password: password);
      state = AuthState(user: user, initialized: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> registerSupplier({
    required String name,
    required String phone,
    required String password,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.registerSupplier(
        name: name,
        phone: phone,
        password: password,
        email: email,
      );
      state = AuthState(user: user, initialized: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<bool> refreshSession() => _repo.refreshSession();

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(initialized: true);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
