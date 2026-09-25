import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/farm/presentation/providers/farm_providers.dart';
import '../../features/notifications/data/models/notification_models.dart';
import '../../features/notifications/data/notifications_api.dart';
import '../../features/notifications/presentation/providers/notifications_providers.dart';
import '../../features/notifications/presentation/utils/resolve_notification_copy.dart';
import '../../features/settings/presentation/providers/app_prefs_provider.dart';

/// Route to open after a local-notification tap (incl. cold start).
final pendingNotificationRouteProvider = StateProvider<String?>((_) => null);

/// Free realtime-ish alerts without Firebase:
/// poll the existing inbox API + show OS local notifications.
///
/// ponytail: polls while app is usable; no OS wake when process is killed.
/// Upgrade path: FCM/APNs later if killed-app delivery becomes required.
class NotificationSyncService with WidgetsBindingObserver {
  NotificationSyncService(this._ref, this._api);

  final Ref _ref;
  final NotificationsApi _api;

  static const _prefsKey = 'notif_seen_recipient_ids_v1';
  static const _channelId = 'doodh_wala_inbox';
  static const _pollInterval = Duration(seconds: 20);

  final _plugin = FlutterLocalNotificationsPlugin();
  Timer? _timer;
  bool _started = false;
  bool _pluginReady = false;
  Set<String> _seen = {};

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    await _initPlugin();
    await _loadSeen();
    await _consumeLaunchDetails();
    _schedule();
    unawaited(poll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
    _started = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(poll());
      _schedule();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (!_ref.read(authControllerProvider).isAuthenticated) return;
    _timer = Timer.periodic(_pollInterval, (_) => unawaited(poll()));
  }

  Future<void> poll() async {
    final auth = _ref.read(authControllerProvider);
    if (!auth.isAuthenticated) return;
    try {
      final items = await _api.list(limit: 30);
      final fresh = unreadNotYetSeen(items, _seen);
      if (fresh.isEmpty) {
        _invalidateInbox();
        return;
      }
      for (final n in fresh) {
        _seen.add(n.recipientId);
        await _showLocal(n);
        if (n.type == 'SERVICE_REQUEST_CREATED') {
          _ref.invalidate(farmDashboardProvider);
        }
      }
      await _saveSeen();
      _invalidateInbox();
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationSync] poll failed: $e');
    }
  }

  void _invalidateInbox() {
    _ref.invalidate(notificationsListProvider);
    _ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> _initPlugin() async {
    if (_pluginReady) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
        ),
        onDidReceiveNotificationResponse: _onTap,
      );
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      _pluginReady = true;
    } catch (e) {
      // Desktop / unsupported platforms: keep polling + in-app inbox only.
      if (kDebugMode) {
        debugPrint('[NotificationSync] local notifications unavailable: $e');
      }
      _pluginReady = false;
    }
  }

  Future<void> _consumeLaunchDetails() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    final response = details?.notificationResponse;
    if (details?.didNotificationLaunchApp == true && response != null) {
      _onTap(response);
    }
  }

  void _onTap(NotificationResponse response) {
    final route = routeFromPayload(response.payload);
    if (route == null) return;
    _ref.read(pendingNotificationRouteProvider.notifier).state = route;
  }

  Future<void> _showLocal(AppNotificationModel n) async {
    if (!_pluginReady) return;
    final lang = _ref.read(appPrefsProvider).locale.languageCode;
    final copy = resolveNotificationCopy(
      lang,
      title: n.title,
      body: n.body,
      data: n.data,
      type: n.type,
    );
    const android = AndroidNotificationDetails(
      _channelId,
      'Doodh Wala',
      channelDescription: 'Milk request and delivery alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      id: n.recipientId.hashCode,
      title: copy.title,
      body: copy.body,
      notificationDetails: const NotificationDetails(
        android: android,
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode({
        'route': n.route,
        'recipientId': n.recipientId,
        'type': n.type,
        'requestId': n.data['requestId'],
      }),
    );
  }

  Future<void> _loadSeen() async {
    final prefs = await SharedPreferences.getInstance();
    _seen = (prefs.getStringList(_prefsKey) ?? const []).toSet();
  }

  Future<void> _saveSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed =
        _seen.toList().reversed.take(200).toList().reversed.toList();
    _seen = trimmed.toSet();
    await prefs.setStringList(_prefsKey, trimmed);
  }
}

/// Pure helper — kept testable without plugin/network.
List<AppNotificationModel> unreadNotYetSeen(
  List<AppNotificationModel> items,
  Set<String> seenIds,
) {
  return items
      .where((n) => n.isUnread && !seenIds.contains(n.recipientId))
      .toList();
}

String? routeFromPayload(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  try {
    final map = jsonDecode(payload);
    if (map is Map) {
      final route = map['route']?.toString();
      final requestId = map['requestId']?.toString();
      final type = map['type']?.toString() ?? '';
      if (route != null && route.isNotEmpty) {
        // Upgrade legacy list routes to exact request targets.
        if (requestId != null &&
            requestId.isNotEmpty &&
            (route == '/farm/requests' || route == '/customer/requests')) {
          if (route.startsWith('/farm')) {
            return '/farm/requests/$requestId';
          }
          return '/customer/requests?focus=$requestId';
        }
        return route;
      }
      if (requestId != null && requestId.isNotEmpty) {
        if (type.contains('ACCEPTED') || type.contains('CANCELLED')) {
          return '/customer/requests?focus=$requestId';
        }
        return '/farm/requests/$requestId';
      }
    }
  } catch (_) {
    if (payload.startsWith('/')) return payload;
  }
  return null;
}

final notificationSyncServiceProvider =
    Provider<NotificationSyncService>((ref) {
  final service = NotificationSyncService(
    ref,
    ref.watch(notificationsApiProvider),
  );
  ref.onDispose(service.stop);
  return service;
});
