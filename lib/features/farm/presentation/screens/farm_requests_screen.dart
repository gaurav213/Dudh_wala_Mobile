import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/models/marketplace_models.dart';
import '../../../../core/utils/delivery_shift_helpers.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/farm_providers.dart';

class FarmRequestsScreen extends ConsumerWidget {
  const FarmRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final requestsAsync = ref.watch(farmServiceRequestsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: requestsAsync.when(
        data: (requests) {
          final pending =
              requests.where((r) => r.isPending).toList(growable: false);
          final accepted =
              requests.where((r) => r.isAccepted).toList(growable: false);
          if (pending.isEmpty && accepted.isEmpty) {
            return const DkEmpty(
              message:
                  'No milk requests yet.\nWhen customers request delivery, they appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(farmServiceRequestsProvider);
              await refreshFarmDashboard(ref);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (pending.isNotEmpty) ...[
                  _SectionHeader(
                    label: l10n.pending.toUpperCase(),
                    count: pending.length,
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 8),
                  ...pending.map(
                    (r) => _InboxCard(
                      request: r,
                      accent: AppColors.warning,
                      onOpen: () =>
                          context.push(AppRoutes.farmRequestDetail(r.id)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (accepted.isNotEmpty) ...[
                  _SectionHeader(
                    label: l10n.approve.toUpperCase(),
                    count: accepted.length,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 8),
                  ...accepted.map(
                    (r) => _InboxCard(
                      request: r,
                      accent: AppColors.success,
                      onOpen: () =>
                          context.push(AppRoutes.farmRequestDetail(r.id)),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DkEmpty(
          message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(farmServiceRequestsProvider),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          "$label ($count)",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _InboxCard extends StatelessWidget {
  const _InboxCard({
    required this.request,
    required this.accent,
    required this.onOpen,
  });

  final ServiceRequestModel request;
  final Color accent;
  final VoidCallback onOpen;

  String _initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final avatar = mediaUrl(request.customerAvatarUrl);
    final when = request.isAccepted
        ? 'Accepted ${formatRelativeTime(request.createdAt)}'
        : 'Requested ${formatRelativeTime(request.createdAt)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Dk.of(context).milkWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Dk.of(context).foam,
                      backgroundImage:
                          avatar != null ? NetworkImage(avatar) : null,
                      child: avatar == null
                          ? Text(
                              _initials(request.customerName),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        request.customerName ?? l10n.customer,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      request.isPending ? l10n.pending : l10n.accept,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  request.productName ?? l10n.milk,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    formatLitresString(request.quantity),
                    request.scheduleLabel,
                    deliveryShiftLabel(request.deliveryShift),
                  ].join(' · '),
                  style: TextStyle(color: Dk.of(context).muted),
                ),
                const SizedBox(height: 6),
                Text(when,
                    style:
                        TextStyle(color: Dk.of(context).muted, fontSize: 12)),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onOpen,
                    child: Text("${l10n.view} ${l10n.requests}"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
