import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../delivery_staff/data/models/delivery_staff_models.dart';
import '../../../delivery_staff/presentation/widgets/delivery_tile.dart';
import '../providers/customer_deliveries_providers.dart';
import 'customer_extra_request_screen.dart';

const _issueTypes = {
  'NOT_RECEIVED': 'Not received',
  'WRONG_QUANTITY': 'Wrong quantity',
  'WRONG_PRODUCT': 'Wrong product',
  'QUALITY_ISSUE': 'Quality issue',
  'OTHER': 'Other',
};

class CustomerDeliveryDetailScreen extends ConsumerStatefulWidget {
  const CustomerDeliveryDetailScreen(
      {super.key, required this.deliveryId, this.initial});

  final String deliveryId;
  final DeliveryModel? initial;

  @override
  ConsumerState<CustomerDeliveryDetailScreen> createState() =>
      _CustomerDeliveryDetailScreenState();
}

class _CustomerDeliveryDetailScreenState
    extends ConsumerState<CustomerDeliveryDetailScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // List/events can diverge: events always hit the API, the delivery card
    // was often the nav `initial` / cached `/me/deliveries` from before farm
    // marked delivered (PENDING + Extra while timeline said MARKED_DELIVERED).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      refreshCustomerDeliveryData(ref, deliveryId: widget.deliveryId);
    });
  }

  DeliveryModel? _findCurrent(List<DeliveryModel> all) {
    for (final d in all) {
      if (d.id == widget.deliveryId) return d;
    }
    return null;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await refreshCustomerDeliveryData(ref, deliveryId: widget.deliveryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).updatedThanks)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skipToday(DeliveryModel d) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.skipMilkConfirmTitle),
        content: Text(l10n.skipMilkConfirmBody(
          formatDate(DateTime.tryParse(d.deliveryDate) ?? DateTime.now()),
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.keepMilk),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.skip),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(
      () => ref.read(customerDeliveriesApiProvider).skipToday(d.id),
    );
  }

  Future<void> _reportProblem(DeliveryModel d) async {
    String issueType = 'NOT_RECEIVED';
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context).reportAProblem),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: issueType,
                decoration:
                    InputDecoration(labelText: AppLocalizations.of(context).whatWentWrong),
                items: [
                  for (final e in _issueTypes.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) =>
                    setDialogState(() => issueType = v ?? issueType),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).describeIssueOptional),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppLocalizations.of(context).submit),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    await _run(
      () => ref.read(customerDeliveriesApiProvider).reportIssue(
            d.id,
            issueType: issueType,
            description:
                controller.text.trim().isEmpty ? null : controller.text.trim(),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deliveriesAsync = ref.watch(customerRecentDeliveriesProvider);
    final eventsAsync =
        ref.watch(customerDeliveryEventsProvider(widget.deliveryId));

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(l10n.delivery)),
      body: deliveriesAsync.when(
        data: (all) {
          final d = _findCurrent(all) ?? widget.initial;
          if (d == null) {
            return DkEmpty(message: AppLocalizations.of(context).deliveryNotFound);
          }
          return _body(d, eventsAsync);
        },
        // Never paint stale `initial` while refetching — that showed PENDING
        // + Extra after the farm already marked delivered.
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          children: [
            const SizedBox(height: 80),
            DkEmpty(
              message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
              actionLabel: l10n.retry,
              onAction: () => ref.invalidate(customerRecentDeliveriesProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
      DeliveryModel d, AsyncValue<List<DeliveryEventModel>> eventsAsync) {
    final l10n = AppLocalizations.of(context);
    final color = deliveryStatusColor(d.status);

    return RefreshIndicator(
      onRefresh: () =>
          refreshCustomerDeliveryData(ref, deliveryId: widget.deliveryId),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Dk.of(context).milkWhite,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      formatDate(
                          DateTime.tryParse(d.deliveryDate) ?? DateTime.now()),
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const Spacer(),
                    Chip(
                      label: Text(
                        d.status.replaceAll('_', ' '),
                        style: TextStyle(fontSize: 12, color: color),
                      ),
                      backgroundColor: color.withValues(alpha: 0.12),
                      side: BorderSide.none,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Row(AppLocalizations.of(context).shift, d.deliveryShift),
                if ((d.productName ?? '').isNotEmpty)
                  _Row('Product', d.productName!),
                _Row(
                  'Rate',
                  '${formatRupees(num.tryParse(d.ratePerLitre) ?? 0)}/L',
                ),
                _Row(
                  'Regular',
                  formatLitres(num.tryParse(d.scheduledQuantity) ?? 0),
                ),
                _Row(
                  'Extra',
                  formatLitres(
                    (num.tryParse(d.customerExtraQuantity) ?? 0) +
                        (num.tryParse(d.staffExtraQuantity) ?? 0),
                  ),
                ),
                if ((num.tryParse(d.staffExtraQuantity) ?? 0) > 0)
                  _Row(
                    'Of which staff added',
                    formatLitres(num.tryParse(d.staffExtraQuantity) ?? 0),
                  ),
                _Row(
                  'Total quantity',
                  formatLitres(
                    num.tryParse(
                          d.finalDeliveredQuantity ?? d.expectedQuantity,
                        ) ??
                        0,
                  ),
                ),
                _Row('Amount', formatRupees(num.tryParse(d.amount) ?? 0)),
                if ((d.deliveryNotes ?? '').isNotEmpty)
                  _Row('Notes', d.deliveryNotes!),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (d.status == 'PENDING' || d.status == 'OUT_FOR_DELIVERY') ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _skipToday(d),
                icon: const Icon(Icons.do_not_disturb_on_outlined),
                label: Text(l10n.noMilkThisDay),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : () => _reportProblem(d),
              icon: const Icon(Icons.flag_outlined, color: AppColors.danger),
              label: Text(AppLocalizations.of(context).reportAProblem,
                  style: TextStyle(color: AppColors.danger)),
            ),
          ),
          const SizedBox(height: 8),
          if (d.status != 'SKIPPED')
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => context.push(
                  AppRoutes.customerExtraRequest,
                  extra: CustomerExtraRequestArgs(
                    subscriptionId: d.subscriptionId,
                    deliveryDate: d.deliveryDate,
                  ),
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: Text(l10n.extraMilk),
              ),
            ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context).timeline, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          eventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return Text(AppLocalizations.of(context).noUpdatesYet,
                    style: TextStyle(color: Dk.of(context).muted));
              }
              return Column(
                children: [
                  for (final e in events.reversed)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Dk.of(context).milkWhite,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _customerEventTitle(e),
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                if ((e.notes ?? '').isNotEmpty)
                                  Text(e.notes!,
                                      style: TextStyle(
                                          color: Dk.of(context).muted)),
                              ],
                            ),
                          ),
                          Text(
                            formatDateTime(e.createdAt),
                            style: TextStyle(
                                color: Dk.of(context).muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) =>
                Text('$e', style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child:
                  Text(label, style: TextStyle(color: Dk.of(context).muted))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

String _customerEventTitle(DeliveryEventModel e) {
  switch (e.eventType) {
    case 'MARKED_DELIVERED':
      final q = e.quantity;
      if (q != null && q.trim().isNotEmpty) {
        return 'Delivered ${formatLitresString(q)}';
      }
      return 'Delivered';
    case 'OUT_FOR_DELIVERY':
      return 'Out for delivery';
    case 'CUSTOMER_MARKED_RECEIVED':
      return 'You confirmed received';
    case 'CUSTOMER_CONFIRMED':
      return 'Confirmed';
    case 'DELIVERY_EDITED':
      final q = e.quantity;
      if (q != null && q.trim().isNotEmpty) {
        return 'Quantity updated to ${formatLitresString(q)}';
      }
      return 'Quantity updated';
    case 'SKIPPED':
      return 'Skipped';
    case 'FAILED':
      return 'Failed';
    case 'CANCELLED':
      return 'Cancelled';
    default:
      return e.eventType.replaceAll('_', ' ');
  }
}
