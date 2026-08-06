import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../environment/app_environment.dart';
import '../errors/app_exception.dart';
import '../storage/token_storage.dart';

typedef RefreshTokensCallback = Future<bool> Function();

class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    required RefreshTokensCallback onRefresh,
    Dio? dio,
    AppEnvironment? env,
  })  : _tokenStorage = tokenStorage,
        _onRefresh = onRefresh,
        _env = env ?? AppEnvironment.current {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: _env.apiBaseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 30),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
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
  final AppEnvironment _env;
  bool _refreshing = false;

  Dio get raw => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }
    if (err.requestOptions.extra['retried'] == true) {
      handler.next(err);
      return;
    }
    if (_refreshing) {
      handler.next(err);
      return;
    }
    _refreshing = true;
    try {
      final ok = await _onRefresh();
      if (!ok) {
        handler.next(err);
        return;
      }
      final token = await _tokenStorage.readAccessToken();
      final req = err.requestOptions;
      req.headers['Authorization'] = 'Bearer $token';
      req.extra['retried'] = true;
      final response = await _dio.fetch(req);
      handler.resolve(response);
    } catch (e) {
      handler.next(err);
    } finally {
      _refreshing = false;
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      _guard(() => _dio.get<T>(path, queryParameters: query));

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
  }) =>
      _guard(() => _dio.post<T>(path, data: data));

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
  }) =>
      _guard(() => _dio.put<T>(path, data: data));

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
  }) =>
      _guard(() => _dio.patch<T>(path, data: data));

  Future<Response<T>> delete<T>(String path) =>
      _guard(() => _dio.delete<T>(path));

  Future<Response<T>> _guard<T>(Future<Response<T>> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  AppException _mapDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String message = e.message ?? 'Network error';
    if (data is Map && data['message'] != null) {
      message = data['message'].toString();
    }
    if (status == 401 || status == 403) {
      return AuthException(message, code: '$status', cause: e);
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return NetworkException('Unable to reach server', cause: e);
    }
    return NetworkException(message, code: status?.toString(), cause: e);
  }
}
