import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/notification_models.dart';
import '../providers/notifications_providers.dart';
import '../utils/resolve_notification_copy.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    AppNotificationModel n,
  ) async {
    if (n.isUnread) {
      await ref.read(notificationsApiProvider).markRead(n.recipientId);
    }
    if (!context.mounted) return;
    final route = n.route;
    if (route != null && route.isNotEmpty) {
      context.go(route);
    } else {
      await context.push(AppRoutes.notificationDetail(n.recipientId));
    }
    if (context.mounted) {
      invalidateNotifications(ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifications = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).clearAll,
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await ref.read(notificationsApiProvider).markAllRead();
              invalidateNotifications(ref);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => invalidateNotifications(ref),
        child: notifications.when(
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  DkEmpty(message: l10n.noNotifications),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final n = items[i];
                final copy = resolveNotificationCopy(
                  Localizations.localeOf(context).languageCode,
                  title: n.title,
                  body: n.body,
                  data: n.data,
                  type: n.type,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Dk.of(context).foam,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _open(context, ref, n),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.circle, size: 10, color: AppColors.leaf),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    copy.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Dk.of(context).ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    copy.body,
                                    style:
                                        TextStyle(color: Dk.of(context).muted),
                                  ),
                                  if (n.createdAt != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      formatDateTime(n.createdAt!),
                                      style: TextStyle(
                                        color: Dk.of(context).muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: Dk.of(context).muted),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 80),
              DkEmpty(
                message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
                actionLabel: l10n.retry,
                onAction: () => invalidateNotifications(ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
