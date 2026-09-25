import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/jwt_utils.dart';
import '../environment/app_environment.dart';
import '../errors/app_exception.dart';
import '../storage/token_storage.dart';
import 'api_base_url_store.dart';

typedef RefreshTokensCallback = Future<bool> Function();
typedef AuthFailureCallback = FutureOr<void> Function();

/// Marker in [RequestOptions.extra] to skip Authorization header attachment.
const kSkipAuthHeader = 'skipAuthHeader';

/// Marker to skip the 401 → refresh → retry flow (login/refresh/logout).
const kSkipAuthRefresh = 'skipAuthRefresh';

class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    required RefreshTokensCallback onRefresh,
    AuthFailureCallback? onRefreshFailed,
    Dio? dio,
    AppEnvironment? env,
    String? baseUrl,
  })  : _tokenStorage = tokenStorage,
        _onRefresh = onRefresh,
        _onRefreshFailed = onRefreshFailed,
        _env = env ?? AppEnvironment.current {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl ?? ApiBaseUrlStore.current,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
    if (_env.enableApiLogs && kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  late final Dio _dio;
  final TokenStorage _tokenStorage;
  final RefreshTokensCallback _onRefresh;
  final AuthFailureCallback? _onRefreshFailed;
  final AppEnvironment _env;

  Completer<bool>? _refreshCompleter;

  Dio get raw => _dio;

  String get baseUrl => _dio.options.baseUrl;

  void setBaseUrl(String url) {
    _dio.options.baseUrl = ApiBaseUrlStore.normalize(url);
  }

  bool _isAuthPath(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/register') ||
        path.contains('/auth/logout');
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final skipHeader = options.extra[kSkipAuthHeader] == true;
    final skipRefresh =
        options.extra[kSkipAuthRefresh] == true || _isAuthPath(options.path);

    if (!skipHeader) {
      // Proactively refresh shortly before access-token expiry.
      if (!skipRefresh) {
        final access = await _tokenStorage.readAccessToken();
        if (JwtUtils.isExpiredOrExpiring(access)) {
          final refreshed = await _refreshTokens();
          if (!refreshed) {
            // Let the request proceed; 401 handler will force logout if needed.
          }
        }
      }
      final token = await _tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final options = err.requestOptions;
    final skipRefresh =
        options.extra[kSkipAuthRefresh] == true || _isAuthPath(options.path);

    if (status != 401 || skipRefresh) {
      handler.next(err);
      return;
    }
    if (options.extra['retried'] == true) {
      final refresh = await _tokenStorage.readRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        await _handleRefreshFailure();
      }
      handler.next(err);
      return;
    }

    final refreshed = await _refreshTokens();
    if (!refreshed) {
      final refresh = await _tokenStorage.readRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        await _handleRefreshFailure();
      }
      handler.next(err);
      return;
    }

    try {
      final token = await _tokenStorage.readAccessToken();
      options.headers['Authorization'] = 'Bearer $token';
      options.extra['retried'] = true;
      final response = await _dio.fetch(options);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }

  /// Single-flight refresh — concurrent 401s await the same attempt.
  Future<bool> _refreshTokens() async {
    final existing = _refreshCompleter;
    if (existing != null) return existing.future;

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    try {
      final ok = await _onRefresh();
      completer.complete(ok);
      return ok;
    } catch (e) {
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _handleRefreshFailure() async {
    final cb = _onRefreshFailed;
    if (cb != null) await cb();
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? extra,
  }) =>
      _guard(
        () => _dio.get<T>(
          path,
          queryParameters: query,
          options: extra == null ? null : Options(extra: extra),
        ),
      );

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? extra,
  }) =>
      _guard(
        () => _dio.post<T>(
          path,
          data: data,
          options: extra == null ? null : Options(extra: extra),
        ),
      );

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? extra,
  }) =>
      _guard(
        () => _dio.put<T>(
          path,
          data: data,
          options: extra == null ? null : Options(extra: extra),
        ),
      );

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? extra,
  }) =>
      _guard(
        () => _dio.patch<T>(
          path,
          data: data,
          options: extra == null ? null : Options(extra: extra),
        ),
      );

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? extra,
  }) =>
      _guard(
        () => _dio.delete<T>(
          path,
          data: data,
          options: extra == null ? null : Options(extra: extra),
        ),
      );

  Future<Response<T>> _guard<T>(Future<Response<T>> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  AppException _mapDio(DioException e) {
    final status = e.response?.statusCode;
    final message = _extractErrorMessage(e);
    if (status == 401) {
      return AuthException(message, code: '401', cause: e);
    }
    if (status == 403) {
      return AuthException(message, code: '403', cause: e);
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkException(
        'Unable to reach server. Check that the phone and computer are on the same network.',
        cause: e,
      );
    }
    return NetworkException(message, code: status?.toString(), cause: e);
  }

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final details = data['details'];
      if (details is List && details.isNotEmpty) {
        return details.map((e) => e.toString()).join('\n');
      }
      if (details is Map && details.isNotEmpty) {
        return details.values.map((e) => e.toString()).join('\n');
      }
      final raw = data['message'] ?? data['error'];
      if (raw is List && raw.isNotEmpty) {
        return raw.map((e) => e.toString()).join('\n');
      }
      if (raw != null && raw.toString().trim().isNotEmpty) {
        return raw.toString();
      }
    }
    if (e.message != null && e.message!.trim().isNotEmpty) {
      return e.message!;
    }
    return 'Something went wrong. Please try again.';
  }
}
