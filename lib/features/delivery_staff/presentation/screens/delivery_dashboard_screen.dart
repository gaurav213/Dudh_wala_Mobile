import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../core/widgets/dk_skeleton.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../notifications/presentation/utils/resolve_notification_copy.dart';
import '../../data/models/delivery_staff_models.dart';
import '../providers/delivery_staff_providers.dart';

class DeliveryDashboardScreen extends ConsumerWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final dashboard = ref.watch(deliveryStaffDashboardProvider);

    // Shell already provides AppBar/drawer — only render body content here.
    return RefreshIndicator(
      color: AppColors.leaf,
      onRefresh: () async {
        ref.invalidate(deliveryStaffDashboardProvider);
        try {
          await ref.read(deliveryStaffDashboardProvider.future);
        } catch (_) {}
      },
      child: dashboard.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        data: (d) => _DashboardBody(dashboard: d, greeting: user?.name),
        loading: () => DkSkeleton.deliveryDashboard(context),
        error: (e, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            DkEmpty(
              message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
              actionLabel: AppLocalizations.of(context).retry,
              onAction: () => ref.invalidate(deliveryStaffDashboardProvider),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.dashboard, this.greeting});

  final DeliveryStaffDashboard dashboard;
  final String? greeting;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          AppLocalizations.of(context).hiGreeting(greeting ?? AppLocalizations.of(context).thereFallback),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Dk.of(context).ink,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          "${AppLocalizations.of(context).datesToday} · ${dashboard.date}",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Dk.of(context).ink,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.push(AppRoutes.deliveryRoute),
            icon: Icon(Icons.play_arrow_rounded),
            label: Text(AppLocalizations.of(context).deliver),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.7,
          children: [
            _CountCard(
              label: AppLocalizations.of(context).pending,
              value: '${dashboard.pending}',
              icon: Icons.schedule,
              color: AppColors.warning,
              onTap: () =>
                  context.push(AppRoutes.deliveryTodayFiltered('pending')),
            ),
            _CountCard(
              label: AppLocalizations.of(context).outForDelivery,
              value: '${dashboard.outForDelivery}',
              icon: Icons.local_shipping_outlined,
              color: AppColors.teal,
              onTap: () => context.push(AppRoutes.deliveryTodayFiltered('out')),
            ),
            _CountCard(
              label: AppLocalizations.of(context).delivered,
              value: '${dashboard.delivered}',
              icon: Icons.check_circle_outline,
              color: AppColors.success,
              onTap: () =>
                  context.push(AppRoutes.deliveryTodayFiltered('delivered')),
            ),
            _CountCard(
              label: AppLocalizations.of(context).failed,
              value:
                  '${dashboard.skipped + dashboard.failed + dashboard.disputed}',
              icon: Icons.error_outline,
              color: AppColors.danger,
              onTap: () =>
                  context.push(AppRoutes.deliveryTodayFiltered('issues')),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: AppLocalizations.of(context).litres,
                value: formatLitres(num.tryParse(dashboard.plannedLitres) ?? 0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: AppLocalizations.of(context).delivered,
                value:
                    formatLitres(num.tryParse(dashboard.deliveredLitres) ?? 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: AppLocalizations.of(context).remaining,
                value: formatRupees(num.tryParse(dashboard.cashToCollect) ?? 0),
                accent: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: AppLocalizations.of(context).collected,
                value: formatRupees(
                    num.tryParse(dashboard.paymentsCollectedToday) ?? 0),
                accent: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(AppLocalizations.of(context).more,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _NavTile(
          icon: Icons.route_outlined,
          title: AppLocalizations.of(context).route,
          subtitle:
              '${dashboard.totalToday} stop(s) · nearest-first when location on',
          onTap: () => context.push(AppRoutes.deliveryRoute),
        ),
        _NavTile(
          icon: Icons.local_shipping_outlined,
          title: AppLocalizations.of(context).deliveries,
          subtitle: AppLocalizations.of(context).customersTodayCount('${dashboard.totalToday}'),
          onTap: () => context.push(AppRoutes.deliveryToday),
        ),
        _NavTile(
          icon: Icons.people_outline,
          title: AppLocalizations.of(context).customers,
          onTap: () => context.push(AppRoutes.deliveryCustomers),
        ),
        _NavTile(
          icon: Icons.add_shopping_cart_outlined,
          title: AppLocalizations.of(context).navExtraRequests,
          subtitle: dashboard.extraRequests > 0
              ? '${dashboard.extraRequests} pending'
              : null,
          badgeCount: dashboard.extraRequests,
          onTap: () => context.push(AppRoutes.deliveryExtraRequests),
        ),
        if (dashboard.permissions?.canRecordCashPayment == true)
          _NavTile(
            icon: Icons.payments_outlined,
            title: AppLocalizations.of(context).collections,
            onTap: () => context.push(AppRoutes.deliveryCollections),
          ),
        _NavTile(
          icon: Icons.history,
          title: AppLocalizations.of(context).history,
          onTap: () => context.push(AppRoutes.deliveryStaffHistory),
        ),
        _NavTile(
          icon: Icons.star_outline,
          title: AppLocalizations.of(context).rate,
          onTap: () => context.push(AppRoutes.deliveryReviews),
        ),
        if (dashboard.recentNotifications.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context).notifications,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final n in dashboard.recentNotifications)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Builder(
                builder: (context) {
                  final copy = resolveNotificationCopy(
                    Localizations.localeOf(context).languageCode,
                    title: n.title,
                    body: n.body,
                    data: n.data,
                    type: n.data['type']?.toString(),
                  );
                  return ListTile(
                    tileColor: Dk.of(context).milkWhite,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    leading: Icon(
                      n.readAt == null ? Icons.circle : Icons.circle_outlined,
                      size: 12,
                      color: n.readAt == null
                          ? AppColors.leaf
                          : Dk.of(context).muted,
                    ),
                    title: Text(copy.title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(copy.body,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      final route = n.route;
                      if (route != null && route.isNotEmpty) {
                        context.push(route);
                      } else {
                        context.push(AppRoutes.deliveryNotifications);
                      }
                    },
                  );
                },
              ),
            ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Dk.of(context).milkWhite,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text(label,
                style: TextStyle(color: Dk.of(context).muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Dk.of(context).milkWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: Dk.of(context).muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: accent ?? Dk.of(context).ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        tileColor: Dk.of(context).milkWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: AppColors.leaf),
        title: Text(title, style: TextStyle(color: Dk.of(context).ink)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: TextStyle(color: Dk.of(context).muted)),
        trailing: badgeCount > 0
            ? CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.leaf,
                child: Text(
                  "$badgeCount",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
            : Icon(Icons.chevron_right, color: Dk.of(context).muted),
        onTap: onTap,
      ),
    );
  }
}
