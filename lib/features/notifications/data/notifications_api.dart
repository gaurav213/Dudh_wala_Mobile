import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/json_parsing.dart';
import 'models/notification_detail_models.dart';
import 'models/notification_models.dart';

/// Dio-backed data source for the shared (all-role) notifications inbox.
class NotificationsApi {
  NotificationsApi(this._api);

  final ApiClient _api;

  Object? _unwrap(Response<Map<String, dynamic>> res) {
    final body = res.data;
    if (body == null) {
      throw const NetworkException('Empty response from server');
    }
    return body.containsKey('data') ? body['data'] : body;
  }

  List<Map<String, dynamic>> _unwrapList(Response<Map<String, dynamic>> res) {
    final data = _unwrap(res);
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  Future<List<AppNotificationModel>> list(
      {int page = 1, int limit = 30}) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/notifications',
      query: {'page': page, 'limit': limit},
    );
    return _unwrapList(res).map(AppNotificationModel.fromJson).toList();
  }

  Future<int> unreadCount() async {
    final res =
        await _api.get<Map<String, dynamic>>('/notifications/unread-count');
    final body = _unwrap(res) as Map<String, dynamic>?;
    return asInt(body?['count']);
  }

  Future<NotificationDetailModel> detail(String recipientId) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/notifications/$recipientId',
    );
    final body = res.data ?? const <String, dynamic>{};
    final root = body.containsKey('data') ? body['data'] : body;
    return NotificationDetailModel.fromJson(
      Map<String, dynamic>.from(root as Map),
    );
  }

  Future<void> markRead(String recipientId) =>
      _api.post<void>('/notifications/$recipientId/read');

  Future<void> markAllRead() => _api.post<void>('/notifications/read-all');

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceId,
  }) =>
      _api.post<void>(
        '/device-tokens',
        data: {
          'token': token,
          'platform': platform,
          if (deviceId != null) 'deviceId': deviceId,
        },
      );

  Future<void> unregisterDeviceToken(String token) =>
      _api.delete<void>('/device-tokens', data: {'token': token});
}
