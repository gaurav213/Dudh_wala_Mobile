import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../data/remote/auth_remote_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Dedicated client for login/refresh/logout — never attempts token refresh.
final authHttpClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    onRefresh: () async => false,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    tokens: ref.watch(tokenStorageProvider),
    remote: AuthRemoteSource(ref.watch(authHttpClientProvider)),
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
  Completer<bool>? _refreshCompleter;

  Future<void> bootstrap() async {
    if (state.initialized || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      // Secure storage can be slow on desktop; allow enough time for restore +
      // a quiet refresh when the access token has expired.
      final user = await _repo.restoreSession().timeout(
            const Duration(seconds: 30),
            onTimeout: () => _repo.restoreCachedUser(),
          );
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

  Future<void> registerFarmOwner({
    required String name,
    required String phone,
    required String password,
    required String farmName,
    required String addressLine1,
    required String area,
    required String city,
    required String stateName,
    required String postalCode,
    String? businessName,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.registerFarmOwner(
        name: name,
        phone: phone,
        password: password,
        farmName: farmName,
        addressLine1: addressLine1,
        area: area,
        city: city,
        state: stateName,
        postalCode: postalCode,
        businessName: businessName,
        email: email,
      );
      state = AuthState(user: user, initialized: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> registerCustomer({
    required String name,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.registerCustomer(
        name: name,
        phone: phone,
        password: password,
      );
      state = AuthState(user: user, initialized: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Used by [ApiClient] on 401 / proactive refresh. Single-flight.
  Future<bool> refreshSession() async {
    final existing = _refreshCompleter;
    if (existing != null) return existing.future;

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    try {
      final ok = await _repo.refreshSession();
      // Only drop the session when the refresh token was cleared (auth rejected).
      if (!ok && !await _repo.hasSession()) {
        await forceLocalLogout();
      }
      completer.complete(ok);
      return ok;
    } catch (_) {
      if (!await _repo.hasSession()) {
        await forceLocalLogout();
      }
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Refresh token invalid/expired/revoked — drop session and send user to Login.
  Future<void> forceLocalLogout() async {
    await _repo.clearLocalSession();
    state = const AuthState(initialized: true);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(initialized: true);
  }

  Future<void> updateProfile({String? name, String? email}) async {
    final user = await _repo.updateProfile(name: name, email: email);
    state = state.copyWith(user: user);
  }

  Future<void> uploadAvatar(String filePath) async {
    final user = await _repo.uploadAvatar(filePath);
    state = state.copyWith(user: user);
  }

  Future<void> deleteAccount() async {
    await _repo.deleteAccount();
    state = const AuthState(initialized: true);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
