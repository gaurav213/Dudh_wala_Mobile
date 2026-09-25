import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/notifications/presentation/providers/notifications_providers.dart';
import '../../features/notifications/presentation/widgets/notifications_popup.dart';
import '../../l10n/app_localizations.dart';

/// App bar bell with unread badge — full inbox route or popup sheet only.
class NotificationBellAction extends ConsumerWidget {
  const NotificationBellAction({
    super.key,
    required this.route,
    this.popupOnly = false,
    this.extraBadgeCount = 0,
  });

  final String route;
  final bool popupOnly;

  /// Optional extra count (e.g. farm pending milk requests) merged into badge.
  final int extraBadgeCount;

  static const _iconColor = Colors.white;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadNotificationCountProvider);
    final unread = unreadAsync.maybeWhen(data: (n) => n, orElse: () => 0);
    final count = unread > extraBadgeCount ? unread : extraBadgeCount;

    return IconButton(
      tooltip: AppLocalizations.of(context).notifications,
      color: _iconColor,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text("$count"),
        child: const Icon(Icons.notifications_outlined, color: _iconColor),
      ),
      onPressed: () {
        if (popupOnly) {
          showNotificationsPopup(context, ref);
        } else {
          context.push(route);
        }
      },
    );
  }
}
