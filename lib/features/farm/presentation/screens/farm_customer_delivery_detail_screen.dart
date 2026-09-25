import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../delivery_staff/presentation/providers/delivery_staff_providers.dart';
import '../providers/farm_providers.dart';
import 'farm_today_deliveries_screen.dart';

/// Farm-owner view: one customer’s milk for a chosen day + month summary.
class FarmCustomerDeliveryDetailScreen extends ConsumerStatefulWidget {
  const FarmCustomerDeliveryDetailScreen({
    super.key,
    required this.customerId,
    this.initialDateIso,
  });

  final String customerId;
  final String? initialDateIso;

  @override
  ConsumerState<FarmCustomerDeliveryDetailScreen> createState() =>
      _FarmCustomerDeliveryDetailScreenState();
}

class _FarmCustomerDeliveryDetailScreenState
    extends ConsumerState<FarmCustomerDeliveryDetailScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _parseDay(widget.initialDateIso) ?? _today;
  }

  DateTime? _parseDay(String? iso) {
    if (iso == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(iso)) {
      return null;
    }
    final p = DateTime.parse(iso);
    return DateTime(p.year, p.month, p.day);
  }

  String get _iso {
    final d = _selectedDate;
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get _yesterday => _today.subtract(const Duration(days: 1));
  DateTime get _tomorrow => _today.add(const Duration(days: 1));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: _today.add(const Duration(days: 7)),
    );
    if (picked == null) return;
    setState(
        () => _selectedDate = DateTime(picked.year, picked.month, picked.day));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detailAsync =
        ref.watch(deliveryStaffCustomerDetailProvider(widget.customerId));
    final dayRange = FarmDashboardDateRange(from: _iso, to: _iso);
    final dayAsync = ref.watch(farmTodayDeliveriesProvider(dayRange));
    final dayRows = dayAsync.valueOrNull
            ?.where((d) => '${d['customerId']}' == widget.customerId)
            .toList() ??
        const <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(
        title: Text(l10n.customerMilk),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.farmToday);
            }
          },
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DkEmpty(
          message: '$e',
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(
              deliveryStaffCustomerDetailProvider(widget.customerId)),
        ),
        data: (detail) {
          final billing = detail.billing;
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                  deliveryStaffCustomerDetailProvider(widget.customerId));
              ref.invalidate(farmTodayDeliveriesProvider(
                  FarmDashboardDateRange(from: _iso, to: _iso)));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  detail.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (detail.mobileNumber != null)
                  Text(detail.mobileNumber!,
                      style: TextStyle(color: Dk.of(context).muted)),
                if ((detail.address ?? '').isNotEmpty)
                  Text(detail.address!,
                      style: TextStyle(color: Dk.of(context).muted)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.datesToday),
                      selected: _selectedDate == _today,
                      onSelected: (_) => setState(() => _selectedDate = _today),
                    ),
                    ChoiceChip(
                      label: Text(l10n.datesTomorrow),
                      selected: _selectedDate == _tomorrow,
                      onSelected: (_) =>
                          setState(() => _selectedDate = _tomorrow),
                    ),
                    ChoiceChip(
                      label: Text(l10n.datesYesterday),
                      selected: _selectedDate == _yesterday,
                      onSelected: (_) =>
                          setState(() => _selectedDate = _yesterday),
                    ),
                    ActionChip(
                      label: Text(
                        _selectedDate == _today ||
                                _selectedDate == _tomorrow ||
                                _selectedDate == _yesterday
                            ? l10n.pickDate
                            : formatDate(_selectedDate),
                      ),
                      onPressed: _pickDate,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.thisDay(formatDate(_selectedDate)),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (dayAsync.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (dayRows.isEmpty)
                  Text(
                    l10n.noMilkStopsCustomer,
                    style: TextStyle(color: Dk.of(context).muted),
                  )
                else
                  ...dayRows.map((d) {
                    final status = '${d['status'] ?? ''}';
                    final notes =
                        '${d['deliveryNotes'] ?? d['delivery_notes'] ?? ''}';
                    final customerNoMilk =
                        status == 'SKIPPED' && notes.contains('Customer:');
                    final qty =
                        '${d['finalDeliveredQuantity'] ?? d['expectedQuantity'] ?? d['scheduledQuantity'] ?? ''}';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: customerNoMilk
                            ? AppColors.danger.withValues(alpha: 0.1)
                            : Dk.of(context).milkWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: customerNoMilk
                            ? Border.all(color: AppColors.danger)
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "${formatLitresString(qty)} · ${d['deliveryShift'] ?? ''}",                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: customerNoMilk
                                        ? AppColors.danger
                                        : null,
                                  ),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  customerNoMilk ? l10n.noMilk : status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: customerNoMilk
                                        ? AppColors.danger
                                        : null,
                                  ),
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          if (customerNoMilk) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.customerDoesNotWantMilk,
                              style: TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 20),
                Text(l10n.tillDateThisMonth,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _grid(context, [
                  (
                    l10n.deliveredTillDate,
                    formatLitresString(billing?.monthTotalQuantity ?? '0')
                  ),
                  (
                    l10n.extraTillDate,
                    formatLitresString(billing?.monthExtraQuantity ?? '0')
                  ),
                  (
                    l10n.pendingCash,
                    formatRupees(
                        double.tryParse(billing?.outstandingBalance ?? '0') ??
                            0)
                  ),
                  (
                    l10n.givenThisMonth,
                    formatRupees(
                        double.tryParse(billing?.paymentsThisMonth ?? '0') ?? 0)
                  ),
                  (
                    l10n.advance,
                    formatRupees(
                        double.tryParse(billing?.advanceBalance ?? '0') ?? 0)
                  ),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _generateBillTillToday(context, ref),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: Text(l10n.generateBill),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _generateBillTillToday(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final now = DateTime.now();
    final month =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    try {
      await ref.read(farmApiProvider).generateMonthBill(
            customerId: widget.customerId,
            billingMonth: month,
          );
      ref.invalidate(deliveryStaffCustomerDetailProvider(widget.customerId));
      await ref
          .read(deliveryStaffCustomerDetailProvider(widget.customerId).future);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).billUpdatedTillToday),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Widget _grid(BuildContext context, List<(String, String)> items) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.8,
      children: [
        for (final (label, value) in items)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Dk.of(context).milkWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style:
                        TextStyle(color: Dk.of(context).muted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
          ),
      ],
    );
  }
}
