import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/notification_bell_action.dart';
import '../../../../core/widgets/dk_skeleton.dart';
import '../../../../core/widgets/sync_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_providers.dart';
import '../../../../l10n/app_localizations.dart';

class SupplierDashboardScreen extends ConsumerWidget {
  const SupplierDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).appTitle),
            Text(
              user?.name ?? 'Supplier',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          const SyncBadge(),
          NotificationBellAction(route: AppRoutes.notifications),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.leaf,
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          try {
            await ref.read(dashboardStatsProvider.future);
          } catch (_) {}
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              AppLocalizations.of(context).todayDotDate(formatDate(DateTime.now())),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            stats.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              data: (s) => _StatsGrid(stats: s),
              loading: () => DkSkeleton.supplierStatsGrid(),
              error: (_, __) => DkSkeleton.supplierStatsGrid(),
            ),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context).quickActions,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionChip(
                  label: "Today's deliveries",
                  icon: Icons.local_shipping_outlined,
                  onTap: () => context.push(AppRoutes.todaysDeliveries),
                ),
                _ActionChip(
                  label: 'Customers',
                  icon: Icons.people_outline,
                  onTap: () => context.push(AppRoutes.customers),
                ),
                _ActionChip(
                  label: 'Generate bill',
                  icon: Icons.receipt_long_outlined,
                  onTap: () => context.push(AppRoutes.generateBill),
                ),
                _ActionChip(
                  label: 'Outstanding',
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: () => context.push(AppRoutes.outstanding),
                ),
                _ActionChip(
                  label: 'Calendar',
                  icon: Icons.calendar_month_outlined,
                  onTap: () => context.push(AppRoutes.calendar),
                ),
                _ActionChip(
                  label: 'Sync',
                  icon: Icons.sync,
                  onTap: () => context.push(AppRoutes.syncStatus),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final Map<String, num> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: [
        _StatTile(
            label: 'Customers', value: '${stats['customers']?.toInt() ?? 0}'),
        _StatTile(
          label: 'Today litres',
          value: formatLitres(stats['today_litres'] ?? 0),
        ),
        _StatTile(
          label: 'Deliveries',
          value:
              '${stats['delivered']?.toInt() ?? 0}/${stats['today_deliveries']?.toInt() ?? 0}',
        ),
        _StatTile(
          label: 'Outstanding',
          valueWidget: AmountText(stats['outstanding_due'] ?? 0),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, this.value, this.valueWidget});
  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Dk.of(context).milkWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.leaf.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: Dk.of(context).muted, fontSize: 13)),
          const Spacer(),
          valueWidget ??
              Text(
                value ?? '',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.leafDark,
                      fontWeight: FontWeight.w700,
                    ),
              ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.leaf),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
