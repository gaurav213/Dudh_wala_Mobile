import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/widgets/notification_bell_action.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/l10n/delivery_labels.dart';
import '../../../../core/widgets/dk_skeleton.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../customer_deliveries/presentation/providers/customer_deliveries_providers.dart';
import '../../../customer_deliveries/presentation/screens/customer_extra_request_screen.dart';
import '../../../customer_deliveries/presentation/widgets/customer_cash_claim.dart';
import '../../../customer_marketplace/presentation/providers/customer_ledger_providers.dart';
import '../../../customer_marketplace/presentation/providers/customer_marketplace_providers.dart';

class CustomerDashboardScreen extends ConsumerStatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  ConsumerState<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState
    extends ConsumerState<CustomerDashboardScreen> {
  bool _skipBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final id = ref.read(authControllerProvider).user?.id;
      _refreshCustomerDashboard(ref, id);
    });
  }

  Future<void> _skipToday(String deliveryId) async {
    if (_skipBusy) return;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.skipMilkConfirmTitle),
        content: Text(l10n.skipMilkConfirmBody(l10n.datesToday)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.keepMilk),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.noMilkTodayBtn),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _skipBusy = true);
    try {
      await ref.read(customerDeliveriesApiProvider).skipToday(deliveryId);
      await _refreshCustomerDashboard(
        ref,
        ref.read(authControllerProvider).user?.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.farmNotifiedSkipped)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _skipBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).user;
    final todaysMilk = ref.watch(customerTodaysDeliveriesProvider);
    final billTillToday = ref.watch(customerBillTillTodayProvider);
    final bills = ref.watch(customerAwareBillsProvider(user?.id));
    final requests = ref.watch(customerServiceRequestsProvider);
    final invitations = ref.watch(customerInvitationsProvider);

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(
        title: Text(user?.name ?? l10n.customerMilk),
        actions: [
          NotificationBellAction(
            route: AppRoutes.customerNotifications,
            popupOnly: true,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.leaf,
        onRefresh: () => _refreshCustomerDashboard(ref, user?.id),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            invitations.maybeWhen(
              data: (list) {
                final pending = list.where((e) => e.isPending).length;
                if (pending == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Dk.of(context).foam,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.go(AppRoutes.customerRequests),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(Icons.mail_outline, color: AppColors.leaf),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                pending == 1
                                    ? '1 farm invitation waiting — tap to accept'
                                    : '$pending farm invitations waiting — tap to accept',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Dk.of(context).ink,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: Dk.of(context).muted),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            Text(
              "${l10n.datesToday} · ${formatDate(DateTime.now())}",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Dk.of(context).ink,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            todaysMilk.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              data: (list) {
                if (list.isEmpty) {
                  return _TapCard(
                    onTap: () => context.push(AppRoutes.customerCalendar),
                    child: Text(
                      AppLocalizations.of(context).noDeliveryScheduledOpenCalendar,
                      style: TextStyle(color: Dk.of(context).ink),
                    ),
                  );
                }
                final d = list.first;
                final litres = num.tryParse(
                      d.finalDeliveredQuantity ?? d.expectedQuantity,
                    ) ??
                    0;
                return _TodaysMilkCard(
                  litres: litres,
                  shift: d.deliveryShift,
                  status: d.status,
                  productName: d.productName,
                  ratePerLitre: d.ratePerLitre,
                  regular: d.scheduledQuantity,
                  customerExtra: d.customerExtraQuantity,
                  staffExtra: d.staffExtraQuantity,
                  amount: d.amount,
                  deliveredAt: d.deliveredAt,
                  deliveryNotes: d.deliveryNotes,
                  skipBusy: _skipBusy,
                  canSkip:
                      d.status == 'PENDING' || d.status == 'OUT_FOR_DELIVERY',
                  onTap: () => context.push(
                    AppRoutes.customerDeliveryDetail(d.id),
                    extra: d,
                  ),
                  onRequestExtra: () => context.push(
                    AppRoutes.customerExtraRequest,
                    extra: CustomerExtraRequestArgs(
                      subscriptionId: d.subscriptionId,
                      deliveryDate: d.deliveryDate,
                    ),
                  ),
                  onSkipToday: () => _skipToday(d.id),
                );
              },
              loading: () => DkSkeleton.box(height: 132, borderRadius: 14),
              error: (e, _) => _TapCard(
                onTap: () => _refreshCustomerDashboard(ref, user?.id),
                child: Text(
                  AppLocalizations.of(context).couldNotLoadTodaysMilkRetry('$e'),
                  style: TextStyle(color: Dk.of(context).ink),
                ),
              ),
            ),
            const SizedBox(height: 12),
            billTillToday.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              data: (summary) => CustomerBillingMonthStrip(
                summary: summary,
                onOpenBilling: () => context.push(AppRoutes.customerBilling),
              ),
              loading: () => DkSkeleton.box(height: 168, borderRadius: 16),
              error: (e, _) => _TapCard(
                onTap: () => _refreshCustomerDashboard(ref, user?.id),
                child: Text(
                  AppLocalizations.of(context).couldNotLoadBillRetry('$e'),
                  style: TextStyle(color: Dk.of(context).ink),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.findFarms,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Dk.of(context).ink,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            _NavTile(
              icon: Icons.storefront_outlined,
              title: l10n.findFarms,
              subtitle: AppLocalizations.of(context).searchByDeliveryAddress,
              onTap: () => context.push(AppRoutes.customerFindFarms),
            ),
            _NavTile(
              icon: Icons.inbox_outlined,
              title: l10n.navInbox,
              subtitle: () {
                final reqCount = requests.maybeWhen(
                  data: (r) => r.length,
                  orElse: () => 0,
                );
                final invPending = invitations.maybeWhen(
                  data: (i) => i.where((e) => e.isPending).length,
                  orElse: () => 0,
                );
                if (reqCount == 0 && invPending == 0) {
                  return l10n.inboxSubtitleEmpty;
                }
                return l10n.inboxSubtitleCounts(
                  '$reqCount',
                  '$invPending',
                );
              }(),
              onTap: () => context.push(AppRoutes.customerRequests),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.customerMilk,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Dk.of(context).ink,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            _NavTile(
              icon: Icons.calendar_month_outlined,
              title: l10n.deliveryCalendar,
              onTap: () => context.push(AppRoutes.customerCalendar),
            ),
            _NavTile(
              icon: Icons.history,
              title: l10n.history,
              onTap: () => context.push(AppRoutes.customerHistory),
            ),
            _NavTile(
              icon: Icons.receipt_long_outlined,
              title: l10n.bills,
              subtitle: bills.maybeWhen(
                data: (b) => b.isEmpty
                    ? l10n.billsSubtitleEmpty
                    : l10n.billsCount('${b.length}'),
                orElse: () => l10n.billsSubtitleEmpty,
              ),
              onTap: () => context.push(AppRoutes.customerBilling),
            ),
            _NavTile(
              icon: Icons.payments_outlined,
              title: l10n.payments,
              onTap: () => context.push(AppRoutes.customerPayments),
            ),
            _NavTile(
              icon: Icons.account_balance_wallet_outlined,
              title: l10n.billing,
              onTap: () => context.push(AppRoutes.customerBilling),
            ),
            _NavTile(
              icon: Icons.local_shipping_outlined,
              title: l10n.navExtraRequests,
              onTap: () => context.push(AppRoutes.customerExtraRequest),
            ),
            _NavTile(
              icon: Icons.reviews_outlined,
              title: l10n.reviews,
              onTap: () => context.push(AppRoutes.customerReviewsReceived),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _refreshCustomerDashboard(WidgetRef ref, String? userId) async {
  ref.invalidate(customerRecentDeliveriesProvider);
  ref.invalidate(customerTodaysDeliveriesProvider);
  ref.invalidate(customerBillTillTodayProvider);
  ref.invalidate(customerAwareBillsProvider(userId));
  ref.invalidate(customerServiceRequestsProvider);
  ref.invalidate(customerInvitationsProvider);
  try {
    await Future.wait([
      ref.read(customerTodaysDeliveriesProvider.future),
      ref.read(customerBillTillTodayProvider.future),
      ref.read(customerAwareBillsProvider(userId).future),
      ref.read(customerServiceRequestsProvider.future),
      ref.read(customerInvitationsProvider.future),
    ]);
  } catch (_) {}
}

/// Extra for the customer = customer-requested + staff-added (both are extra milk).
String _formatLitresLocalized(AppLocalizations l10n, num litres) {
  final v = litres.toDouble();
  final n = v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(2);
  return '$n ${l10n.litres}';
}

String _extraBreakdownLine(
  AppLocalizations l10n, {
  required String regular,
  required String customerExtra,
  required String staffExtra,
}) {
  final regularQty = num.tryParse(regular) ?? 0;
  final customerQty = num.tryParse(customerExtra) ?? 0;
  final staffQty = num.tryParse(staffExtra) ?? 0;
  final totalExtra = customerQty + staffQty;

  var line = l10n.regularExtraLine(
    _formatLitresLocalized(l10n, regularQty),
    _formatLitresLocalized(l10n, totalExtra),
  );
  if (customerQty > 0 && staffQty > 0) {
    line +=
        ' ${l10n.extraYouAndStaff(_formatLitresLocalized(l10n, customerQty), _formatLitresLocalized(l10n, staffQty))}';
  } else if (staffQty > 0 && customerQty <= 0) {
    line += l10n.fromStaffSuffix;
  }
  return line;
}

class _TodaysMilkCard extends StatelessWidget {
  const _TodaysMilkCard({
    required this.litres,
    required this.shift,
    required this.status,
    this.productName,
    this.ratePerLitre,
    required this.regular,
    required this.customerExtra,
    required this.staffExtra,
    required this.amount,
    this.deliveredAt,
    this.deliveryNotes,
    required this.onTap,
    required this.onRequestExtra,
    required this.onSkipToday,
    required this.canSkip,
    this.skipBusy = false,
  });

  final num litres;
  final String shift;
  final String status;
  final String? productName;
  final String? ratePerLitre;
  final String regular;
  final String customerExtra;
  final String staffExtra;
  final String amount;
  final DateTime? deliveredAt;
  final String? deliveryNotes;
  final VoidCallback onTap;
  final VoidCallback onRequestExtra;
  final VoidCallback onSkipToday;
  final bool canSkip;
  final bool skipBusy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final delivered = status == 'DELIVERED';
    final skipped = status == 'SKIPPED';
    final customerSkipped =
        skipped && (deliveryNotes ?? '').contains('Customer:');
    final farmNotDelivering = skipped && !customerSkipped;
    final cardColor = farmNotDelivering ? AppColors.danger : AppColors.leaf;
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                farmNotDelivering
                    ? l10n.todayFarmNotDelivering
                    : customerSkipped
                        ? l10n.todaysMilkYouSkipped
                        : delivered
                            ? l10n.todaysMilkDelivered
                            : l10n.todaysMilk,
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  fontSize: 12,
                ),
              ),
              if (farmNotDelivering) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.farmNotDeliveringBody,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
              if (delivered &&
                  !farmNotDelivering &&
                  litres + 0.0005 <
                      (num.tryParse(regular) ?? 0) +
                          (num.tryParse(customerExtra) ?? 0)) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.lessThanUsualCharged(_formatLitresLocalized(l10n, litres)),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatLitresLocalized(l10n, litres),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '· ${localizedDeliveryShift(l10n, shift)} · ${localizedDeliveryStatus(l10n, status)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if ((productName ?? '').isNotEmpty ||
                  (ratePerLitre != null &&
                      (num.tryParse(ratePerLitre!) ?? 0) > 0))
                Text(
                  [
                    if ((productName ?? '').isNotEmpty) productName!,
                    if (ratePerLitre != null &&
                        (num.tryParse(ratePerLitre!) ?? 0) > 0)
                      '${formatRupees(num.tryParse(ratePerLitre!) ?? 0)}/${l10n.litres}',
                  ].join(' · '),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              Text(
                _extraBreakdownLine(
                  l10n,
                  regular: regular,
                  customerExtra: customerExtra,
                  staffExtra: staffExtra,
                ),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                "${l10n.amountValue(formatRupees(num.tryParse(amount) ?? 0))}${deliveredAt != null ? ' · ${TimeOfDay.fromDateTime(deliveredAt!.toLocal()).format(context)}' : ''}",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (canSkip)
                    TextButton.icon(
                      onPressed: skipBusy ? null : onSkipToday,
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.white),
                      icon: skipBusy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.do_not_disturb_on_outlined,
                              size: 18),
                      label: Text(l10n.noMilkTodayBtn),
                    ),
                  if (!skipped)
                    TextButton.icon(
                      onPressed: skipBusy ? null : onRequestExtra,
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.white),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: Text(l10n.extraMilk),
                    ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapCard extends StatelessWidget {
  const _TapCard({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Dk.of(context).milkWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.leaf.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Expanded(child: child),
              Icon(Icons.chevron_right, color: Dk.of(context).muted),
            ],
          ),
        ),
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
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

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
        trailing: Icon(Icons.chevron_right, color: Dk.of(context).muted),
        onTap: onTap,
      ),
    );
  }
}
