import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../customer_deliveries/presentation/providers/customer_deliveries_providers.dart';
import '../../../customer_marketplace/presentation/providers/customer_ledger_providers.dart';
import '../../../deliveries/presentation/providers/delivery_providers.dart';

class DeliveryCalendarScreen extends ConsumerStatefulWidget {
  const DeliveryCalendarScreen({super.key});

  @override
  ConsumerState<DeliveryCalendarScreen> createState() =>
      _DeliveryCalendarScreenState();
}

class _DeliveryCalendarScreenState
    extends ConsumerState<DeliveryCalendarScreen> {
  late DateTime _selected;
  bool _busy = false;
  final Set<String> _dedupedDates = {};

  num _asNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  bool get _canSkipSelectedDay {
    final today = DateTime.now();
    final t = DateTime(today.year, today.month, today.day);
    return !_selected.isBefore(t);
  }

  bool _isCustomerSkipped(Map<String, Object?> d) {
    final status = '${d['status'] ?? ''}';
    if (status != 'SKIPPED') return false;
    final notes =
        '${d['notes'] ?? d['deliveryNotes'] ?? d['delivery_notes'] ?? ''}';
    return notes.contains('Customer:');
  }

  bool _dayAlreadySkipped(List<Map<String, Object?>> list) {
    if (list.isEmpty) return false;
    return list.every(_isCustomerSkipped);
  }

  /// One card when the day is fully customer-skipped (avoids morning+evening twins).
  List<Map<String, Object?>> _displayList(List<Map<String, Object?>> list) {
    if (list.length <= 1) return list;
    if (_dayAlreadySkipped(list)) return [list.first];
    return list;
  }

  void _showDeliveryInfo(Map<String, Object?> d) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Dk.of(context).milkWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (d['customer_name'] as String?) ?? l10n.delivery,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    color: Dk.of(context).ink,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Text("${l10n.day}: ${formatDate(_selected)}"),
            const SizedBox(height: 4),
            Text(
                "${l10n.quantityL}: ${formatLitres(_asNum(d['quantity_litres']))}"),
            const SizedBox(height: 4),
            Text("${l10n.amount}: ${formatRupees(_asNum(d['amount']))}"),
            const SizedBox(height: 4),
            Text("${l10n.status}: ${d['status'] ?? '—'}"),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshDay() async {
    ref.invalidate(customerAwareDeliveriesForDateProvider(_selected));
    await refreshCustomerDeliveryData(ref);
    await ref.read(
      customerAwareDeliveriesForDateProvider(_selected).future,
    );
  }

  Future<void> _skipDay() async {
    if (_busy || !_canSkipSelectedDay) return;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.skipMilkConfirmTitle),
        content: Text(l10n.skipMilkConfirmBody(formatDate(_selected))),
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
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(customerDeliveriesApiProvider)
          .skipDay(localDateIso(_selected));
      await _refreshDay();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.farmNotifiedSkipped)),
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

  Future<void> _wantMilkAgain() async {
    if (_busy || !_canSkipSelectedDay) return;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.wantMilkConfirmTitle),
        content: Text(l10n.wantMilkConfirmBody(formatDate(_selected))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.wantMilkAgain),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(customerDeliveriesApiProvider)
          .unskipDay(localDateIso(_selected));
      await _refreshDay();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.farmNotifiedRestored)),
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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isCustomer =
        ref.watch(authControllerProvider).user?.role == UserRole.customer;
    final deliveries = isCustomer
        ? ref.watch(customerAwareDeliveriesForDateProvider(_selected))
        : ref.watch(deliveriesForDateProvider(_selected));

    final list = deliveries.asData?.value ?? const <Map<String, Object?>>[];
    final alreadySkipped = isCustomer && _dayAlreadySkipped(list);
    final showSkip = isCustomer && _canSkipSelectedDay && !alreadySkipped;
    final showWantAgain = isCustomer && _canSkipSelectedDay && alreadySkipped;

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(l10n.deliveryCalendar)),
      body: Column(
        children: [
          CalendarDatePicker(
            initialDate: _selected,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            onDateChanged: (d) => setState(() => _selected = d),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                formatDate(_selected),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Dk.of(context).ink,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          if (showSkip)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _skipDay,
                  icon: const Icon(Icons.do_not_disturb_on_outlined),
                  label: Text(
                    _busy
                        ? l10n.skipping
                        : l10n.noMilkOnDate(formatDate(_selected)),
                  ),
                ),
              ),
            ),
          if (showWantAgain)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _wantMilkAgain,
                  icon: const Icon(Icons.local_drink_outlined),
                  label: Text(
                    _busy
                        ? l10n.updating
                        : l10n.wantMilkOnDate(formatDate(_selected)),
                  ),
                ),
              ),
            ),
          Expanded(
            child: deliveries.when(
              data: (raw) {
                // Clean old duplicate skips once when opening that day.
                if (isCustomer && raw.length > 1 && _dayAlreadySkipped(raw)) {
                  final iso = localDateIso(_selected);
                  if (!_dedupedDates.contains(iso)) {
                    _dedupedDates.add(iso);
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      try {
                        await ref
                            .read(customerDeliveriesApiProvider)
                            .skipDay(iso);
                        if (!mounted) return;
                        ref.invalidate(
                          customerAwareDeliveriesForDateProvider(_selected),
                        );
                      } catch (_) {
                        _dedupedDates.remove(iso);
                      }
                    });
                  }
                }
                final list = isCustomer ? _displayList(raw) : raw;
                if (list.isEmpty) {
                  return DkEmpty(
                    message: isCustomer
                        ? (_canSkipSelectedDay
                            ? l10n.noDeliveryListedYet
                            : l10n.noDeliveriesOnDay)
                        : l10n.noDeliveriesOnDay,
                    actionLabel: isCustomer && !_canSkipSelectedDay
                        ? l10n.findFarms
                        : null,
                    onAction: isCustomer && !_canSkipSelectedDay
                        ? () => context.push(AppRoutes.customerFindFarms)
                        : null,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final d = list[i];
                    final status = '${d['status'] ?? ''}';
                    final customerSkipped = _isCustomerSkipped(d);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: customerSkipped
                            ? AppColors.danger.withValues(alpha: 0.1)
                            : Dk.of(context).milkWhite,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showDeliveryInfo(d),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        (d['customer_name'] as String?) ??
                                            (isCustomer
                                                ? l10n.yourDelivery
                                                : l10n.customer),
                                        style: TextStyle(
                                          color: customerSkipped
                                              ? AppColors.danger
                                              : Dk.of(context).ink,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      formatRupees(_asNum(d['amount'])),
                                      style: TextStyle(
                                        color: Dk.of(context).ink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${formatLitres(_asNum(d['quantity_litres']))} · $status",                                  style: TextStyle(
                                    color: Dk.of(context).muted,
                                  ),
                                ),
                                if (customerSkipped) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.skippedNoMilkDay,
                                    style: TextStyle(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => DkEmpty(
                message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
                actionLabel: l10n.retry,
                onAction: () {
                  if (isCustomer) {
                    ref.invalidate(
                      customerAwareDeliveriesForDateProvider(_selected),
                    );
                  } else {
                    ref.invalidate(deliveriesForDateProvider(_selected));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
