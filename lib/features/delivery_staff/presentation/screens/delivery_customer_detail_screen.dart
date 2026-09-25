import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/utils/json_parsing.dart';
import '../../../../core/utils/launch_helpers.dart';
import '../../../../core/utils/location_helpers.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/delivery_staff_models.dart';
import '../providers/delivery_staff_providers.dart';
import '../widgets/rate_customer_sheet.dart';

class DeliveryCustomerDetailScreen extends ConsumerWidget {
  const DeliveryCustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync =
        ref.watch(deliveryStaffCustomerDetailProvider(customerId));

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(AppLocalizations.of(context).customer)),
      body: detailAsync.when(
        data: (detail) => _Body(detail: detail),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          children: [
            const SizedBox(height: 80),
            DkEmpty(
              message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
              actionLabel: AppLocalizations.of(context).retry,
              onAction: () => ref
                  .invalidate(deliveryStaffCustomerDetailProvider(customerId)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.detail});

  final StaffCustomerDetail detail;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  StaffCustomerDetail get detail => widget.detail;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await refreshDeliveryStaffData(ref);
      ref.invalidate(deliveryStaffCustomerDetailProvider(detail.customerId));
      try {
        await ref.read(
            deliveryStaffCustomerDetailProvider(detail.customerId).future);
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _promptAndAct({
    required String title,
    required Future<void> Function(String? notes, String? qty) action,
    bool needQty = false,
  }) async {
    final notesController = TextEditingController();
    final qtyController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (needQty)
              TextField(
                controller: qtyController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).quantityL),
              ),
            if (needQty) const SizedBox(height: 8),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).notesOptional),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppLocalizations.of(context).cancel)),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppLocalizations.of(context).confirm)),
        ],
      ),
    );
    if (ok != true) return;
    final qty = qtyController.text.trim();
    if (needQty && (double.tryParse(qty) == null || double.parse(qty) <= 0)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).enterValidQuantity)),
        );
      }
      return;
    }
    await _run(
      () => action(
        notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        needQty ? qty : null,
      ),
    );
  }

  Future<void> _addExtraForSubscription(Map<String, dynamic> sub) async {
    await _promptAndAct(
      title: AppLocalizations.of(context).extra,
      needQty: true,
      action: (notes, qty) async {
        final delivery =
            await ref.read(deliveryStaffApiProvider).createAdHocExtra(
                  subscriptionId: asStringOr(sub['id']),
                  extraQuantity: qty!,
                  reason: notes,
                );
        if (mounted) {
          context.push(AppRoutes.deliveryDeliveryDetail(delivery.id),
              extra: delivery);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final billing = detail.billing;
    final canCash = detail.permissions?.canRecordCashPayment == true;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          detail.name,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        if ((detail.mobileNumber ?? '').isNotEmpty)
          Text(detail.mobileNumber!,
              style: TextStyle(color: Dk.of(context).muted)),
        if ((detail.address ?? '').isNotEmpty)
          Text(detail.address!, style: TextStyle(color: Dk.of(context).muted)),
        if ((detail.notes ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Text("${AppLocalizations.of(context).notes}: ${detail.notes}",
              style: TextStyle(color: Dk.of(context).ink)),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    LaunchHelpers.call(context, detail.mobileNumber),
                icon: const Icon(Icons.call_outlined),
                label: Text(AppLocalizations.of(context).call),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    LaunchHelpers.openMap(context, address: detail.address),
                icon: const Icon(Icons.map_outlined),
                label: Text(AppLocalizations.of(context).map),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    final loc = await LocationHelpers.currentPosition(
                        throwOnError: true);
                    if (loc == null) return;
                    try {
                      final route =
                          await ref.read(deliveryStaffApiProvider).routeToday(
                                includeCompleted: true,
                              );
                      final stop =
                          route.stops.cast<DeliveryRouteStop?>().firstWhere(
                                (s) =>
                                    s!.customerId == detail.customerId &&
                                    s.addressId != null,
                                orElse: () => null,
                              );
                      if (stop?.addressId == null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context).noData,
                              ),
                            ),
                          );
                        }
                        return;
                      }
                      await _run(() async {
                        await ref
                            .read(deliveryStaffApiProvider)
                            .updateAddressLocation(
                              addressId: stop!.addressId!,
                              latitude: loc.latitude,
                              longitude: loc.longitude,
                              locationSource: 'DELIVERY_STAFF_MAP_PIN',
                              accuracyMeters: loc.accuracyMeters,
                              markVerified: true,
                            );
                      });
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
            icon: Icon(Icons.edit_location_alt_outlined),
            label: Text(AppLocalizations.of(context).update),
          ),
        ),
        const SizedBox(height: 20),
        Text(AppLocalizations.of(context).datesToday,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (detail.today.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Dk.of(context).milkWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).noData,
                    style: TextStyle(color: Dk.of(context).muted)),
                const SizedBox(height: 10),
                if (detail.subscriptions.isNotEmpty)
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _addExtraForSubscription(
                            detail.subscriptions.first),
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalizations.of(context).extra),
                  ),
              ],
            ),
          )
        else
          for (final d in detail.today)
            _TodayDeliveryCard(
              delivery: d,
              busy: _busy,
              onOpen: () => context.push(AppRoutes.deliveryDeliveryDetail(d.id),
                  extra: d),
              onDeliver: () => _run(
                () async {
                  await ref.read(deliveryStaffApiProvider).markDelivered(d.id);
                },
              ),
              onAddExtra: () => _promptAndAct(
                title: AppLocalizations.of(context).extraMilk,
                needQty: true,
                action: (notes, qty) async {
                  await ref.read(deliveryStaffApiProvider).addExtra(
                        d.id,
                        extraQuantity: qty!,
                        reason: notes,
                      );
                },
              ),
              onSkip: () => _promptAndAct(
                title: AppLocalizations.of(context).skip,
                action: (notes, _) async {
                  await ref
                      .read(deliveryStaffApiProvider)
                      .skip(d.id, notes: notes);
                },
              ),
              onCancel: () => _promptAndAct(
                title: AppLocalizations.of(context).cancel,
                action: (notes, _) async {
                  await ref
                      .read(deliveryStaffApiProvider)
                      .cancel(d.id, notes: notes);
                },
              ),
              onFail: () => _promptAndAct(
                title: AppLocalizations.of(context).failed,
                action: (notes, _) async {
                  await ref
                      .read(deliveryStaffApiProvider)
                      .fail(d.id, notes: notes);
                },
              ),
            ),
        const SizedBox(height: 20),
        Text(AppLocalizations.of(context).subscription,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (detail.subscriptions.isEmpty)
          Text(AppLocalizations.of(context).emptyDefault,
              style: TextStyle(color: Dk.of(context).muted))
        else
          for (final sub in detail.subscriptions) _SubscriptionCard(sub: sub),
        const SizedBox(height: 20),
        if (billing != null) ...[
          Text(AppLocalizations.of(context).billing,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Dk.of(context).milkWhite,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _BillingRow(AppLocalizations.of(context).datesToday,
                    formatRupees(num.tryParse(billing.todaysAmount) ?? 0)),
                _BillingRow(
                  AppLocalizations.of(context).thisMonth,
                  formatRupees(num.tryParse(billing.monthMilkCharges) ?? 0),
                ),
                _BillingRow(
                  AppLocalizations.of(context).payments,
                  formatRupees(num.tryParse(billing.paymentsThisMonth) ?? 0),
                ),
                const Divider(),
                _BillingRow(
                  AppLocalizations.of(context).billing,
                  formatRupees(num.tryParse(billing.billTillToday) ?? 0),
                  emphasize: true,
                ),
                _BillingRow(
                  AppLocalizations.of(context).outstanding,
                  formatRupees(num.tryParse(billing.outstandingBalance) ?? 0),
                  emphasize: true,
                ),
                _BillingRow(
                  AppLocalizations.of(context).advance,
                  formatRupees(num.tryParse(billing.advanceBalance) ?? 0),
                  emphasize: true,
                ),
              ],
            ),
          ),
          if (canCash) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.deliveryCollections),
                icon: Icon(Icons.payments_outlined),
                label: Text(AppLocalizations.of(context).recordCash),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ] else if (detail.permissions?.canViewBillingSummary == false)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              AppLocalizations.of(context).noData,
              style: TextStyle(color: Dk.of(context).muted),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => showRateCustomerSheet(
              context,
              ref,
              customerId: detail.customerId,
              customerUserId: detail.customerUserId,
              customerName: detail.name,
              subscriptions: detail.subscriptions,
            ),
            icon: const Icon(Icons.star_outline),
            label: Text(AppLocalizations.of(context).rate),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _TodayDeliveryCard extends StatelessWidget {
  const _TodayDeliveryCard({
    required this.delivery,
    required this.busy,
    required this.onOpen,
    required this.onDeliver,
    required this.onAddExtra,
    required this.onSkip,
    required this.onCancel,
    required this.onFail,
  });

  final DeliveryModel delivery;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onDeliver;
  final VoidCallback onAddExtra;
  final VoidCallback onSkip;
  final VoidCallback onCancel;
  final VoidCallback onFail;

  @override
  Widget build(BuildContext context) {
    final d = delivery;
    final rate = num.tryParse(d.ratePerLitre) ?? 0;
    final expected = num.tryParse(d.expectedQuantity) ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Dk.of(context).milkWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "${d.deliveryShift} · ${d.status.replaceAll('_', ' ')}",                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                  onPressed: onOpen,
                  child: Text(AppLocalizations.of(context).open)),
            ],
          ),
          _line(context, AppLocalizations.of(context).defaultLabel,
              formatLitres(num.tryParse(d.scheduledQuantity) ?? 0)),
          _line(context, AppLocalizations.of(context).extra,
              formatLitres(num.tryParse(d.customerExtraQuantity) ?? 0)),
          _line(context, AppLocalizations.of(context).extra,
              formatLitres(num.tryParse(d.staffExtraQuantity) ?? 0)),
          _line(context, AppLocalizations.of(context).total,
              formatLitres(expected),
              bold: true),
          _line(context, AppLocalizations.of(context).rate,
              '${formatRupees(rate)}/L'),
          _line(context, AppLocalizations.of(context).todaysAmount,
              formatRupees(num.tryParse(d.amount) ?? 0),
              bold: true),
          if (d.isOpen || d.isDelivered) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (d.isOpen)
                  FilledButton(
                    onPressed: busy ? null : onDeliver,
                    child: Text(AppLocalizations.of(context).markDelivered),
                  ),
                OutlinedButton(
                  onPressed: busy ? null : onAddExtra,
                  child: Text(AppLocalizations.of(context).extra),
                ),
                if (d.isOpen)
                  OutlinedButton(
                    onPressed: busy ? null : onSkip,
                    child: Text(AppLocalizations.of(context).skip),
                  ),
                if (d.isOpen)
                  OutlinedButton(
                    onPressed: busy ? null : onCancel,
                    child: Text(AppLocalizations.of(context).cancel),
                  ),
                if (d.isOpen)
                  OutlinedButton(
                    onPressed: busy ? null : onFail,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger),
                    child: Text(AppLocalizations.of(context).failed),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Dk.of(context).muted)),
          Text(
            value,
            style:
                TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.sub});

  final Map<String, dynamic> sub;

  @override
  Widget build(BuildContext context) {
    final days = sub['deliveryDays'];
    final scheduleType = asStringOr(sub['scheduleType'], 'EVERY_DAY');
    final daysLabel = days is List && days.isNotEmpty
        ? days.map((e) => _weekday(context, e)).join(', ')
        : scheduleType.replaceAll('_', ' ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Dk.of(context).milkWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            asStringOr(sub['milkType'], AppLocalizations.of(context).milk),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          _row(context, AppLocalizations.of(context).defaultLabel,
              formatLitresString('${sub['defaultQuantity'] ?? 0}')),
          _row(context, AppLocalizations.of(context).rate,
              '${formatRupees(num.tryParse('${sub['ratePerLitre'] ?? 0}') ?? 0)}/L'),
          _row(
              context,
              AppLocalizations.of(context).shift,
              asStringOr(
                  sub['deliveryShift'], AppLocalizations.of(context).morning)),
          _row(context, AppLocalizations.of(context).delivery, daysLabel),
          _row(context, AppLocalizations.of(context).from,
              asStringOr(sub['startDate'], '—')),
          _row(context, AppLocalizations.of(context).status,
              asStringOr(sub['status'], '—')),
        ],
      ),
    );
  }

  String _weekday(BuildContext context, dynamic v) {
    final l10n = AppLocalizations.of(context);
    final names = [
      l10n.sunday,
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
    ];
    final n = v is int ? v : int.tryParse('$v');
    if (n == null || n < 0 || n > 6) return '$v';
    return names[n];
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Dk.of(context).muted, fontSize: 13)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _BillingRow extends StatelessWidget {
  const _BillingRow(this.label, this.value, {this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Dk.of(context).muted)),
          Text(
            value,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.leafDark,
            ),
          ),
        ],
      ),
    );
  }
}
