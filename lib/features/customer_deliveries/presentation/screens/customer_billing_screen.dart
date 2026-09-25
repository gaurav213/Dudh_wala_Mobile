import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/l10n/delivery_labels.dart';
import '../../../../core/utils/json_parsing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../billing/data/pdf/bill_pdf_service.dart';
import '../../../billing/presentation/providers/billing_providers.dart';
import '../providers/customer_deliveries_providers.dart';
import '../widgets/customer_cash_claim.dart';

const _billStatusMeaning = {
  'DRAFT': 'Not finalized yet',
  'ISSUED': 'Awaiting payment',
  'PARTIALLY_PAID': 'Partially paid',
  'PAID': 'Paid',
  'OVERDUE': 'Overdue',
  'VOID': 'Cancelled',
};

class CustomerBillingScreen extends ConsumerStatefulWidget {
  const CustomerBillingScreen({super.key});

  @override
  ConsumerState<CustomerBillingScreen> createState() =>
      _CustomerBillingScreenState();
}

class _CustomerBillingScreenState extends ConsumerState<CustomerBillingScreen> {
  bool _pdfBusy = false;

  Future<void> _openPdf({String? billingMonthYyyyMm}) async {
    if (_pdfBusy) return;
    setState(() => _pdfBusy = true);
    try {
      final l10n = AppLocalizations.of(context);
      final summary = await ref.read(customerBillTillTodayProvider.future);
      final user = ref.read(authControllerProvider).user;
      final now = DateTime.now();
      final monthKey = billingMonthYyyyMm ??
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
      final monthStart = '$monthKey-01';
      final parts = monthKey.split('-').map(int.parse).toList();
      final lastDay = DateTime(parts[0], parts[1] + 1, 0).day;
      final monthEnd = '$monthKey-${lastDay.toString().padLeft(2, '0')}';
      final today =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final isCurrent = monthKey ==
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
      final to = isCurrent && today.compareTo(monthEnd) < 0 ? today : monthEnd;

      final deliveries = await ref
          .read(customerDeliveriesApiProvider)
          .recentDeliveries(limit: 100, dateFrom: monthStart, dateTo: to);
      final delivered = deliveries.where((d) => d.isDelivered).toList()
        ..sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));

      final litres = delivered.fold<num>(
        0,
        (a, d) =>
            a + (num.tryParse(d.finalDeliveredQuantity ?? d.quantity) ?? 0),
      );
      final periodLabel = isCurrent
          ? '${formatDate(DateTime.parse(monthStart))} – ${formatDate(DateTime.parse(to))} ${l10n.tillTodayParen}'
          : '${formatDate(DateTime.parse(monthStart))} – ${formatDate(DateTime.parse(monthEnd))}';

      final data = BillPdfData(
        brandName: 'Doodh Wala',
        farmName: 'Your dairy farm',
        billNumber: isCurrent ? 'TD-$monthKey' : 'BL-$monthKey',
        periodLabel: periodLabel,
        generatedOn: formatDate(now),
        customerName: user?.name ?? 'Customer',
        customerPhone: user?.phone ?? '',
        lines: [
          for (final d in delivered)
            BillPdfLine(
              date: formatDate(DateTime.tryParse(d.deliveryDate) ?? now),
              description:
                  '${d.productName ?? l10n.milk} · ${localizedDeliveryShift(l10n, d.deliveryShift)}',
              qty: formatLitresString(d.finalDeliveredQuantity ?? d.quantity),
              rate: formatRupees(num.tryParse(d.ratePerLitre) ?? 0),
              amount: formatRupees(num.tryParse(d.amount) ?? 0),
            ),
        ],
        totalLitres: formatLitres(litres),
        milkCharges: formatRupees(
            num.tryParse('${summary['monthMilkCharges'] ?? 0}') ?? 0),
        previousBalance: formatRupees(
            num.tryParse('${summary['previousBalance'] ?? 0}') ?? 0),
        paid: formatRupees(
            num.tryParse('${summary['paymentsThisMonth'] ?? 0}') ?? 0),
        due:
            formatRupees(num.tryParse('${summary['billTillToday'] ?? 0}') ?? 0),
        statusNote: isCurrent
            ? 'This is your running bill for the month. Pay anytime. Amount due updates after each delivery and payment.'
            : 'Monthly milk bill statement.',
      );

      // For non-current months, recompute milk/paid from that month's lines only.
      if (!isCurrent) {
        final milk =
            delivered.fold<num>(0, (a, d) => a + (num.tryParse(d.amount) ?? 0));
        await ref.read(billPdfServiceProvider).previewAndShare(
              BillPdfData(
                brandName: data.brandName,
                farmName: data.farmName,
                billNumber: data.billNumber,
                periodLabel: data.periodLabel,
                generatedOn: data.generatedOn,
                customerName: data.customerName,
                customerPhone: data.customerPhone,
                lines: data.lines,
                totalLitres: data.totalLitres,
                milkCharges: formatRupees(milk),
                previousBalance: formatRupees(0),
                paid: formatRupees(0),
                due: formatRupees(milk),
                statusNote: data.statusNote,
              ),
            );
      } else {
        await ref.read(billPdfServiceProvider).previewAndShare(data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final billsAsync = ref.watch(customerBillsProvider);
    final billTillTodayAsync = ref.watch(customerBillTillTodayProvider);

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(
        title: Text(l10n.billing),
        actions: [
          TextButton.icon(
            onPressed: _pdfBusy ? null : () => _openPdf(),
            icon: _pdfBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            label: Text(AppLocalizations.of(context).pdf),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerBillsProvider);
          ref.invalidate(customerBillTillTodayProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            billTillTodayAsync.when(
              data: (summary) => CustomerBillingMonthStrip(
                summary: summary,
                leafStyle: true,
              ),
              loading: () => const SizedBox(
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (e, _) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.leaf,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "${AppLocalizations.of(context).couldNotLoad}.\n$e",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _pdfBusy ? null : () => _openPdf(),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label:
                    Text(_pdfBusy
                        ? AppLocalizations.of(context).preparingPdf
                        : AppLocalizations.of(context).viewShareBillPdf),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(AppLocalizations.of(context).thisMonthAndEarlier,
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push(AppRoutes.customerPayments),
                  child: Text(l10n.payments),
                ),
              ],
            ),
            const SizedBox(height: 8),
            billsAsync.when(
              data: (bills) {
                if (bills.isEmpty) {
                  return Text(
                    AppLocalizations.of(context).noDeliveredMilkThisMonthYet,
                    style: TextStyle(color: Dk.of(context).muted),
                  );
                }
                return Column(
                  children: [
                    for (final b in bills)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Dk.of(context).milkWhite,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _pdfBusy
                                ? null
                                : () {
                                    final raw =
                                        asStringOr(b['billingMonth'], '');
                                    final ym = raw.length >= 7
                                        ? raw.substring(0, 7)
                                        : null;
                                    _openPdf(billingMonthYyyyMm: ym);
                                  },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          b['tillDate'] == true
                                              ? l10n.billTillTodayLabel(
                                                  asStringOr(
                                                      b['billingMonth'],
                                                      l10n.bills))
                                              : asStringOr(
                                                  b['billingMonth'], l10n.bills),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                        Text(
                                          b['tillDate'] == true
                                              ? 'Tap to open PDF · pay anytime'
                                              : (_billStatusMeaning[asStringOr(
                                                      b['status'])] ??
                                                  asStringOr(b['status'])),
                                          style: TextStyle(
                                              color: Dk.of(context).muted,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        formatRupees(num.tryParse(asStringOr(
                                                b['totalAmount'], '0')) ??
                                            0),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        AppLocalizations.of(context).dueAmount(
                                          formatRupees(num.tryParse(asStringOr(
                                                  b['remainingBalance'],
                                                  '0')) ??
                                              0),
                                        ),
                                        style: const TextStyle(
                                            color: AppColors.warning,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.picture_as_pdf_outlined,
                                      color: Dk.of(context).muted, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text('$e', style: const TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      ),
    );
  }
}
