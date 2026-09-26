import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../core/widgets/dk_skeleton.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/farm_models.dart';
import '../../data/models/farm_ops_models.dart';
import '../providers/farm_providers.dart';

class FarmDashboardScreen extends ConsumerWidget {
  const FarmDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(farmDashboardProvider);
    final today = ref.watch(farmTodayMetricsProvider);
    final range = ref.watch(farmDashboardRangeProvider);

    return RefreshIndicator(
      color: AppColors.leaf,
      onRefresh: () async {
        ref.invalidate(farmDashboardProvider);
        ref.invalidate(farmTodayMetricsProvider);
        try {
          await Future.wait([
            ref.read(farmDashboardProvider.future),
            ref.read(farmTodayMetricsProvider.future),
          ]);
        } catch (_) {}
      },
      child: dashboard.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        data: (d) => _DashboardBody(
          dashboard: d,
          today: today,
          range: range,
          onSelectRange: (r) =>
              ref.read(farmDashboardRangeProvider.notifier).state = r,
        ),
        loading: () => DkSkeleton.farmDashboard(context),
        error: (e, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            DkEmpty(
              message: _friendlyError(e),
              actionLabel: AppLocalizations.of(context).retry,
              onAction: () => ref.invalidate(farmDashboardProvider),
            ),
          ],
        ),
      ),
    );
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('No farm found')) {
      return 'No farm profile found for this account yet.';
    }
    return 'Could not load your farm dashboard.\n$msg';
  }
}

DateTime _parseFarmIso(String iso) {
  final p = iso.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

String _farmIso(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

Future<void> _openPeriodSheet({
  required BuildContext context,
  required List<({String id, String label, String from, String to})> presets,
  required String? selectedId,
  required bool isCustom,
  required FarmDashboardDateRange range,
  required DateTime todayDate,
  required void Function(FarmDashboardDateRange) onSelectRange,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final l10n = AppLocalizations.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  l10n.period,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              for (final p in presets)
                ListTile(
                  leading: Icon(
                    selectedId == p.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color:
                        selectedId == p.id ? AppColors.leaf : Dk.of(ctx).muted,
                  ),
                  title: Text(p.label),
                  onTap: () {
                    onSelectRange(
                      FarmDashboardDateRange(from: p.from, to: p.to),
                    );
                    Navigator.pop(ctx);
                  },
                ),
              ListTile(
                leading: Icon(
                  isCustom
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isCustom ? AppColors.leaf : Dk.of(ctx).muted,
                ),
                title: Text(AppLocalizations.of(context).customRange),
                subtitle: isCustom
                    ? Text(
                        "${formatDate(_parseFarmIso(range.from))} – ${formatDate(_parseFarmIso(range.to))}",
                      )
                    : Text(AppLocalizations.of(context).pickStartAndEndDates),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: todayDate,
                    initialDateRange: DateTimeRange(
                      start: _parseFarmIso(range.from),
                      end: _parseFarmIso(range.to),
                    ),
                    helpText: 'Select custom period',
                  );
                  if (picked != null) {
                    onSelectRange(
                      FarmDashboardDateRange(
                        from: _farmIso(DateTime(
                          picked.start.year,
                          picked.start.month,
                          picked.start.day,
                        )),
                        to: _farmIso(DateTime(
                          picked.end.year,
                          picked.end.month,
                          picked.end.day,
                        )),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.dashboard,
    required this.today,
    required this.range,
    required this.onSelectRange,
  });

  final FarmDashboard dashboard;
  final AsyncValue<FarmTodayMetrics> today;
  final FarmDashboardDateRange range;
  final ValueChanged<FarmDashboardDateRange> onSelectRange;

  DateTime _monthsAgo(DateTime today, int months) {
    var y = today.year;
    var m = today.month - months;
    while (m <= 0) {
      m += 12;
      y -= 1;
    }
    final lastDay = DateTime(y, m + 1, 0).day;
    final day = today.day > lastDay ? lastDay : today.day;
    return DateTime(y, m, day);
  }

  @override
  Widget build(BuildContext context) {
    final farm = dashboard.farm;
    final counts = dashboard.counts;
    final checklist = dashboard.checklist;
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));
    final weekStart = todayDate.subtract(Duration(days: todayDate.weekday - 1));
    final monthStart = DateTime(todayDate.year, todayDate.month, 1);
    final threeMonths = _monthsAgo(todayDate, 3);
    final sixMonths = _monthsAgo(todayDate, 6);
    final yearStart = DateTime(todayDate.year, 1, 1);
    final todayIso = _farmIso(todayDate);
    final yesterdayIso = _farmIso(yesterday);
    final weekIso = _farmIso(weekStart);
    final monthIso = _farmIso(monthStart);
    final threeIso = _farmIso(threeMonths);
    final sixIso = _farmIso(sixMonths);
    final yearIso = _farmIso(yearStart);

    final presets = <({String id, String label, String from, String to})>[
      (id: 'today', label: l10n.datesToday, from: todayIso, to: todayIso),
      (
        id: 'yesterday',
        label: l10n.datesYesterday,
        from: yesterdayIso,
        to: yesterdayIso
      ),
      (id: 'week', label: l10n.datesThisWeek, from: weekIso, to: todayIso),
      (id: 'month', label: l10n.datesThisMonth, from: monthIso, to: todayIso),
      (id: '3m', label: '3 months', from: threeIso, to: todayIso),
      (id: '6m', label: '6 months', from: sixIso, to: todayIso),
      (id: 'year', label: 'This year', from: yearIso, to: todayIso),
    ];
    String? selectedId;
    for (final p in presets) {
      if (p.from == range.from && p.to == range.to) {
        selectedId = p.id;
        break;
      }
    }
    final isCustom = selectedId == null;
    final isToday = selectedId == 'today';
    final rangeLabel = range.isSingleDay
        ? formatDate(_parseFarmIso(range.from))
        : '${formatDate(_parseFarmIso(range.from))} – ${formatDate(_parseFarmIso(range.to))}';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                farm.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            _StatusChip(status: farm.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context).profilePercentComplete('${dashboard.profileCompletionPercent}'),
          style: TextStyle(color: Dk.of(context).muted),
        ),
        if (!farm.isActive) ...[
          const SizedBox(height: 16),
          _PendingApprovalBanner(status: farm.status),
        ],
        if (!checklist.isApproved ||
            !checklist.hasServiceArea ||
            !checklist.hasProduct) ...[
          const SizedBox(height: 16),
          _FarmSetupGuide(checklist: checklist),
        ],
        const SizedBox(height: 20),
        Text(l10n.farmPaisaTitle,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          l10n.period,
          style: TextStyle(
            color: Dk.of(context).muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Dk.of(context).milkWhite,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openPeriodSheet(
              context: context,
              presets: presets,
              selectedId: selectedId,
              isCustom: isCustom,
              range: range,
              todayDate: todayDate,
              onSelectRange: onSelectRange,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.date_range, color: AppColors.leaf, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedId == null
                              ? l10n.customRange
                              : presets
                                  .firstWhere((p) => p.id == selectedId)
                                  .label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Dk.of(context).ink,
                          ),
                        ),
                        Text(
                          rangeLabel,
                          style: TextStyle(
                            color: Dk.of(context).muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.expand_more, color: Dk.of(context).muted),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _FarmDaySummaryCard(
          money: dashboard.money,
          today: today,
          milkTitle: isToday
              ? l10n.todaysMilk
              : '${l10n.milk} · $rangeLabel',
          l10n: l10n,
          showWeekMonth: range.isSingleDay,
        ),
        const SizedBox(height: 20),
        // Simple farmer mode — 4 large primary actions
        _BigActionTile(
          icon: Icons.local_shipping,
          title: l10n.farmAajKiList,
          subtitle: AppLocalizations.of(context).customersToDeliverSubtitle,
          color: AppColors.leaf,
          onTap: () => context.push(AppRoutes.farmToday),
        ),
        const SizedBox(height: 10),
        _BigActionTile(
          icon: Icons.people,
          title: l10n.farmCustomersTile,
          subtitle: AppLocalizations.of(context).nConnected('${counts.connections}'),
          color: AppColors.leaf,
          onTap: () => context.push(AppRoutes.farmCustomers),
        ),
        const SizedBox(height: 10),
        _BigActionTile(
          icon: Icons.move_to_inbox,
          title: l10n.requests,
          subtitle: counts.pendingServiceRequests > 0
              ? l10n.inboxSubtitleCounts(
                  '${counts.pendingServiceRequests}',
                  '0',
                )
              : l10n.navCustomerRequests,
          color: AppColors.warning,
          onTap: () => context.push(AppRoutes.farmRequests),
        ),
        const SizedBox(height: 10),
        _BigActionTile(
          icon: Icons.storefront,
          title: l10n.farmSetupTile,
          subtitle: AppLocalizations.of(context).productsAreasProfile,
          color: Dk.of(context).muted,
          onTap: () => context.push(AppRoutes.farmProfile),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _BigActionTile extends StatelessWidget {
  const _BigActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Dk.of(context).milkWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Dk.of(context).muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Dk.of(context).muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmDaySummaryCard extends StatelessWidget {
  const _FarmDaySummaryCard({
    required this.money,
    required this.today,
    required this.milkTitle,
    required this.l10n,
    this.showWeekMonth = true,
  });

  final FarmMoneySummary money;
  final AsyncValue<FarmTodayMetrics> today;
  final String milkTitle;
  final AppLocalizations l10n;
  final bool showWeekMonth;

  String _rupees(String raw) => formatRupees(num.tryParse(raw) ?? 0);

  @override
  Widget build(BuildContext context) {
    final muted = Dk.of(context).muted;
    final earned = _rupees(money.madeInRange);
    final collected = _rupees(money.collectedInRange);
    final advance = num.tryParse(money.advanceBalance) ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Dk.of(context).milkWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            milkTitle,
            style: TextStyle(
                color: muted, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          today.when(
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
            data: (m) => _TodayMetricsBody(metrics: m, l10n: l10n),
            loading: () => DkSkeleton.box(height: 120, borderRadius: 10),
            error: (_, __) => Text(
              AppLocalizations.of(context).milkMetricsUnavailable,
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ),
          const Divider(height: 28),
          Text(
            AppLocalizations.of(context).stillToCollect,
            style: TextStyle(
                color: muted, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            _rupees(money.toCollect),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).outstandingBalanceHint,
            style: TextStyle(color: muted, fontSize: 12),
          ),
          if (advance > 0) ...[
            const SizedBox(height: 14),
            Text(
              AppLocalizations.of(context).advanceHeld,
              style: TextStyle(
                  color: muted, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              _rupees(money.advanceBalance),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).advanceHeldHint,
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          if (!showWeekMonth) ...[
            Text(
              l10n.farmMadeSection,
              style: TextStyle(
                  color: muted, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              earned,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.farmCollectedSection,
              style: TextStyle(
                  color: muted, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              collected,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ] else ...[
            Text(
              l10n.farmMadeSection,
              style: TextStyle(
                  color: muted, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _MoneyTriple(
              labels: [
                l10n.farmMadeToday,
                l10n.farmMadeWeek,
                l10n.farmMadeMonth
              ],
              values: [
                earned,
                _rupees(money.madeThisWeek),
                _rupees(money.madeThisMonth),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              l10n.farmCollectedSection,
              style: TextStyle(
                  color: muted, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _MoneyTriple(
              labels: [
                l10n.farmCollectedToday,
                l10n.farmCollectedWeek,
                l10n.farmCollectedMonth,
              ],
              values: [
                collected,
                _rupees(money.collectedThisWeek),
                _rupees(money.collectedThisMonth),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MoneyTriple extends StatelessWidget {
  const _MoneyTriple({required this.labels, required this.values});

  final List<String> labels;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Dk.of(context).muted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    values[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TodayMetricsBody extends StatelessWidget {
  const _TodayMetricsBody({required this.metrics, required this.l10n});

  final FarmTodayMetrics metrics;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _metricTap(
          context,
          l10n.scheduledMilk,
          formatLitresString(metrics.scheduledQuantity),
          () => context.push(AppRoutes.farmToday),
        ),
        _metricTap(
          context,
          l10n.extraMilk,
          formatLitresString(metrics.totalExtraQuantity),
          () => context.push(AppRoutes.farmExtraToday),
          subtitle: l10n.customerStaffBreakdown(
            formatLitresString(metrics.customerExtraQuantity),
            formatLitresString(metrics.staffExtraQuantity),
          ),
        ),
        _metricTap(
          context,
          l10n.totalDelivered,
          formatLitresString(metrics.totalDeliveredQuantity),
          () => context.push(AppRoutes.farmToday),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _miniStat(
                context,
                l10n.delivered,
                '${metrics.deliveredCount}',
                () => context.push(AppRoutes.farmToday),
              ),
            ),
            Expanded(
              child: _miniStat(
                context,
                l10n.pending,
                '${metrics.pendingCount}',
                () => context.push(AppRoutes.farmToday),
              ),
            ),
            Expanded(
              child: _miniStat(
                context,
                l10n.skipped,
                '${metrics.skippedCount}',
                () => context.push(AppRoutes.farmToday),
              ),
            ),
            Expanded(
              child: _miniStat(
                context,
                l10n.edited,
                '${metrics.editedDeliveryCount}',
                () => context.push(AppRoutes.farmDeliveriesEdited),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricTap(
    BuildContext context,
    String label,
    String value,
    VoidCallback onTap, {
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Dk.of(context).muted)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 11, color: Dk.of(context).muted)),
                ],
              ),
            ),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(
    BuildContext context,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(value,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          Text(label,
              style: TextStyle(fontSize: 11, color: Dk.of(context).muted)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = status == 'ACTIVE';
    final color = active ? AppColors.success : AppColors.warning;
    final label = switch (status) {
      'ACTIVE' => l10n.farmStatusActive,
      'PENDING_APPROVAL' => l10n.farmStatusPendingApproval,
      'SUSPENDED' => l10n.farmStatusSuspended,
      'REJECTED' => l10n.farmStatusRejected,
      'CLOSED' => l10n.farmStatusClosed,
      'BLOCKED' => l10n.farmStatusBlocked,
      _ => status.replaceAll('_', ' '),
    };
    return Chip(
      label: Text(
        label,
        style:
            TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide.none,
    );
  }
}

class _PendingApprovalBanner extends StatelessWidget {
  const _PendingApprovalBanner({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = switch (status) {
      'PENDING_APPROVAL' => l10n.farmPendingApprovalBanner,
      'SUSPENDED' => l10n.farmSuspendedBanner,
      'REJECTED' => l10n.farmRejectedBanner,
      'CLOSED' => l10n.farmClosedBanner,
      _ => l10n.farmNotVisibleBanner,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _FarmSetupGuide extends StatelessWidget {
  const _FarmSetupGuide({required this.checklist});

  final FarmOnboardingChecklist checklist;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: Dk.of(context).milkWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.leaf.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.getSetUp,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.farmSetupUntilLive,
            style: TextStyle(
              color: Dk.of(context).muted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          _ChecklistTile(
            done: checklist.profileComplete,
            title: '1. ${l10n.completeYourProfile}',
            subtitle: l10n.profileChecklistSubtitle,
            onTap: () => context.push(AppRoutes.farmProfile),
          ),
          _ChecklistTile(
            done: false,
            title: '2. ${l10n.farmSetupAddPhotos}',
            subtitle: l10n.farmSetupAddPhotosHint,
            onTap: () => context.push(AppRoutes.farmProfile),
          ),
          _ChecklistTile(
            done: checklist.hasServiceArea,
            title: '3. ${l10n.addServiceArea}',
            subtitle: l10n.soCustomersCanFindYou,
            onTap: () => context.push(AppRoutes.farmServiceAreas),
          ),
          _ChecklistTile(
            done: checklist.hasProduct,
            title: '4. ${l10n.addMilkProduct}',
            subtitle: l10n.setRateAndMinQty,
            onTap: () => context.push(AppRoutes.farmProducts),
          ),
          if (!checklist.isApproved)
            _ChecklistTile(
              done: false,
              title: '5. ${l10n.farmApproved}',
              subtitle: l10n.waitingPlatformApproval,
              onTap: () => context.push(AppRoutes.farmProfile),
            ),
        ],
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.done,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final bool done;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        tileColor: Dk.of(context).milkWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? AppColors.success : Dk.of(context).muted,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
