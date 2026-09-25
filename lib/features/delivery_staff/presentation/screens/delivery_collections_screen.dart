import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/delivery_staff_models.dart';
import '../providers/delivery_staff_providers.dart';

class DeliveryCollectionsScreen extends ConsumerWidget {
  const DeliveryCollectionsScreen({super.key});

  Future<void> _collect(
      BuildContext context, WidgetRef ref, DeliveryModel d) async {
    final amountController = TextEditingController(text: d.amount);
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            "${AppLocalizations.of(context).recordCash} · ${d.customerName ?? AppLocalizations.of(context).customer}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).amountInr),
            ),
            const SizedBox(height: 8),
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
              child: Text(AppLocalizations.of(context).recordCash)),
        ],
      ),
    );
    if (confirmed != true) return;
    final amount = amountController.text.trim();
    if (double.tryParse(amount) == null || double.parse(amount) <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).enterValidAmount)),
        );
      }
      return;
    }
    try {
      await ref.read(deliveryStaffApiProvider).recordCashPayment(
            customerId: d.customerId,
            farmId: d.farmId,
            amount: amount,
            purpose: 'BILL_PAYMENT',
            paymentDate: localDateIso(),
            notes: notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
          );
      ref.invalidate(deliveryStaffDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).saved)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(deliveryStaffDashboardProvider);
    final deliveriesAsync = ref.watch(todayDeliveriesProvider);

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(AppLocalizations.of(context).collections)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(deliveryStaffDashboardProvider);
          ref.invalidate(todayDeliveriesProvider);
        },
        child: dashboardAsync.when(
          data: (dash) {
            if (dash.permissions?.canRecordCashPayment != true) {
              return ListView(
                children: [
                  SizedBox(height: 80),
                  DkEmpty(
                    message: AppLocalizations.of(context).noData,
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: AppLocalizations.of(context).remaining,
                        value:
                            formatRupees(num.tryParse(dash.cashToCollect) ?? 0),
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: AppLocalizations.of(context).collected,
                        value: formatRupees(
                            num.tryParse(dash.paymentsCollectedToday) ?? 0),
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(AppLocalizations.of(context).delivered,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                deliveriesAsync.when(
                  data: (deliveries) {
                    final delivered =
                        deliveries.where((d) => d.isDelivered).toList();
                    if (delivered.isEmpty) {
                      return DkEmpty(
                          message: AppLocalizations.of(context).emptyDefault);
                    }
                    return Column(
                      children: [
                        for (final d in delivered)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              tileColor: Dk.of(context).milkWhite,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              title: Text(d.customerName ??
                                  AppLocalizations.of(context).customer),
                              subtitle: Text(
                                  formatRupees(num.tryParse(d.amount) ?? 0)),
                              trailing: FilledButton.tonal(
                                onPressed: () => _collect(context, ref, d),
                                child: Text(
                                    AppLocalizations.of(context).recordCash),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('$e',
                      style: const TextStyle(color: AppColors.danger)),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 80),
              DkEmpty(
                  message: '${AppLocalizations.of(context).couldNotLoad}.\n$e'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

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
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
