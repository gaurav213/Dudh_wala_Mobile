import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/notification_models.dart';
import '../providers/notifications_providers.dart';
import '../utils/resolve_notification_copy.dart';

/// In-app notifications as a sheet — no full-screen inbox route.
Future<void> showNotificationsPopup(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Dk.of(context).milkWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (_, scrollController) {
          return Consumer(
            builder: (_, ref, __) {
              final l10n = AppLocalizations.of(sheetContext);
              final notifications = ref.watch(notificationsListProvider);

              Future<void> openItem(AppNotificationModel n) async {
                if (n.isUnread) {
                  await ref
                      .read(notificationsApiProvider)
                      .markRead(n.recipientId);
                  invalidateNotifications(ref);
                }
                if (!sheetContext.mounted) return;
                final route = n.route;
                if (route != null && route.isNotEmpty) {
                  Navigator.of(sheetContext).pop();
                  if (context.mounted) context.go(route);
                  return;
                }
                final copy = resolveNotificationCopy(
                  Localizations.localeOf(sheetContext).languageCode,
                  title: n.title,
                  body: n.body,
                  data: n.data,
                  type: n.type,
                );
                await showDialog<void>(
                  context: sheetContext,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(copy.title),
                    content: SingleChildScrollView(
                      child: Text(
                        copy.body.isEmpty ? l10n.noData : copy.body,
                        style: TextStyle(
                            color: Dk.of(context).muted, height: 1.35),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(l10n.close),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Dk.of(context).muted.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.notifications,
                            style: Theme.of(sheetContext)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Dk.of(context).ink,
                                ),
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.markAllRead,
                          onPressed: () async {
                            await ref
                                .read(notificationsApiProvider)
                                .markAllRead();
                            invalidateNotifications(ref);
                          },
                          icon: const Icon(Icons.done_all),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => invalidateNotifications(ref),
                      child: notifications.when(
                        data: (items) {
                          if (items.isEmpty) {
                            return ListView(
                              controller: scrollController,
                              children: [
                                const SizedBox(height: 40),
                                DkEmpty(message: l10n.noNotifications),
                              ],
                            );
                          }
                          return ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final n = items[i];
                              final copy = resolveNotificationCopy(
                                Localizations.localeOf(sheetContext)
                                    .languageCode,
                                title: n.title,
                                body: n.body,
                                data: n.data,
                                type: n.type,
                              );
                              return Material(
                                color: n.isUnread
                                    ? AppColors.leaf.withValues(alpha: 0.08)
                                    : Dk.of(context).foam,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => openItem(n),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          n.isUnread
                                              ? Icons.circle
                                              : Icons.circle_outlined,
                                          size: 10,
                                          color: n.isUnread
                                              ? AppColors.leaf
                                              : Dk.of(context).muted,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                copy.title,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: Dk.of(context).ink,
                                                ),
                                              ),
                                              if (copy.body.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  copy.body,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Dk.of(context).muted,
                                                    height: 1.3,
                                                  ),
                                                ),
                                              ],
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
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => ListView(
                          controller: scrollController,
                          children: [
                            const SizedBox(height: 40),
                            DkEmpty(
                              message: '${l10n.couldNotLoad}.\n$e',
                              actionLabel: l10n.retry,
                              onAction: () => invalidateNotifications(ref),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}
