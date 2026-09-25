import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/farm_ops_models.dart';
import '../providers/farm_providers.dart';

class FarmStaffDetailScreen extends ConsumerWidget {
  const FarmStaffDetailScreen({super.key, required this.staffUserId});

  final String staffUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detailAsync = ref.watch(farmStaffDetailProvider(staffUserId));
    final todayAsync = ref.watch(farmStaffTodayProvider((staffUserId, 'all')));

    return Scaffold(
      appBar: AppBar(
        title: Text("${l10n.staff} ${l10n.details}"),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            onPressed: () =>
                context.push(AppRoutes.farmStaffSettings(staffUserId)),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DkEmpty(
          message: '$e',
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(farmStaffDetailProvider(staffUserId)),
        ),
        data: (detail) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(farmStaffDetailProvider(staffUserId));
            ref.invalidate(farmStaffTodayProvider((staffUserId, 'all')));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                detail.profile.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                detail.profile.mobileNumber,
                style: TextStyle(color: Dk.of(context).muted),
              ),
              if (detail.profile.email != null) Text(detail.profile.email!),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).statusLifetimeDeliveries(detail.profile.status, '${detail.lifetimeDeliveryCount}'),
                style: TextStyle(color: Dk.of(context).muted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Text(l10n.datesToday,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _statsGrid(context, detail.today),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label:
                        Text("${l10n.pending} (${detail.today.pendingCount})"),
                    onPressed: () => context.push(
                      '${AppRoutes.farmStaffToday(staffUserId)}?section=pending',
                    ),
                  ),
                  ActionChip(
                    label: Text(
                      "${l10n.extra} ${formatLitresString(detail.today.totalExtraQuantity)}",
                    ),
                    onPressed: () => context.push(
                      '${AppRoutes.farmStaffToday(staffUserId)}?section=extra',
                    ),
                  ),
                  ActionChip(
                    label:
                        Text("${l10n.edit} (${detail.editStats.editedToday})"),
                    onPressed: () =>
                        context.push(AppRoutes.farmStaffEdited(staffUserId)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).editedThisWeek('${detail.editStats.editedThisWeek}') + ' · '
                'This month: ${detail.editStats.editedThisMonth}',
                style: TextStyle(color: Dk.of(context).muted, fontSize: 12),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(AppLocalizations.of(context).navTodaysDeliveries,
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        context.push(AppRoutes.farmStaffToday(staffUserId)),
                    child: Text("${l10n.view} ${l10n.all}"),
                  ),
                ],
              ),
              todayAsync.when(
                loading: () => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('$e'),
                data: (data) {
                  if (data.deliveries.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(AppLocalizations.of(context).noDeliveriesAssignedToday,
                          style: TextStyle(color: Dk.of(context).muted)),
                    );
                  }
                  return Column(
                    children: data.deliveries
                        .take(8)
                        .map((row) => _DeliveryTile(row: row))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsGrid(BuildContext context, StaffTodaySummary t) {
    final items = [
      ('Assigned', '${t.assignedCustomers}'),
      ('Delivered', '${t.deliveredCount}'),
      ('Pending', '${t.pendingCount}'),
      ('Skipped', '${t.skippedCount}'),
      ('Scheduled', formatLitresString(t.scheduledQuantity)),
      ('Extra', formatLitresString(t.totalExtraQuantity)),
      ('Total milk', formatLitresString(t.totalDeliveredQuantity)),
      ('Cash', '₹${t.cashCollected}'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.4,
      children: items
          .map(
            (e) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Dk.of(context).milkWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(e.$2,
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(e.$1,
                      style:
                          TextStyle(color: Dk.of(context).muted, fontSize: 12)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DeliveryTile extends StatelessWidget {
  const _DeliveryTile({required this.row});

  final StaffTodayDeliveryRow row;

  @override
  Widget build(BuildContext context) {
    final editedLabel = row.isEdited
        ? (row.editReviewStatus == 'PENDING_REVIEW'
            ? 'Edited · Review required'
            : 'Edited')
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        tileColor: Dk.of(context).milkWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        trailing: const Icon(Icons.chevron_right),
        title: Text(
          row.customerName ?? AppLocalizations.of(context).customer,
        ),
        subtitle: Text(
          [
            if (row.productName != null) row.productName!,
            'Scheduled ${formatLitresString(row.scheduledQuantity)}',
            if (double.tryParse(row.extraQuantity) != null &&
                double.parse(row.extraQuantity) > 0)
              'Extra ${formatLitresString(row.extraQuantity)}',
            if (row.finalDeliveredQuantity != null)
              'Delivered ${formatLitresString(row.finalDeliveredQuantity)}',
            row.status,
            if (editedLabel != null) editedLabel,
          ].join(' · '),
        ),
        onTap: () => context.push(AppRoutes.farmTodayCustomer(row.customerId)),
      ),
    );
  }
}
