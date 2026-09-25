import '../../../../core/utils/json_parsing.dart';

class AppNotificationModel {
  const AppNotificationModel({
    required this.recipientId,
    required this.readAt,
    required this.type,
    required this.title,
    required this.body,
    required this.route,
    required this.data,
    required this.createdAt,
  });

  final String recipientId;
  final DateTime? readAt;
  final String type;
  final String title;
  final String body;
  final String? route;
  final Map<String, dynamic> data;
  final DateTime? createdAt;

  bool get isUnread => readAt == null;

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final notification =
        (json['notification'] as Map?)?.cast<String, dynamic>() ?? const {};
    return AppNotificationModel(
      recipientId: asStringOr(json['recipientId']),
      readAt: parseDateTime(json['readAt']),
      type: asStringOr(notification['type'], 'GENERIC'),
      title: asStringOr(notification['title'], 'Notification'),
      body: asStringOr(notification['body']),
      route: asStringOrNull(notification['route']),
      data: (notification['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      createdAt: parseDateTime(notification['createdAt']),
    );
  }
}
