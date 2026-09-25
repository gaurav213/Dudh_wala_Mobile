import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../customer_marketplace/presentation/providers/customer_ledger_providers.dart';
import '../../../../l10n/app_localizations.dart';

class DeliveryHistoryScreen extends ConsumerWidget {
  const DeliveryHistoryScreen({super.key});

  DateTime? _asDate(Object? value) {
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  num _asNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  void _showDeliveryInfo(BuildContext context, Map<String, Object?> d) {
    final date = _asDate(d['delivery_date']);
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
              date != null ? formatDate(date) : 'Delivery',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    color: Dk.of(context).ink,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context).quantityColon(formatLitres(_asNum(d['quantity_litres'])))),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context).amountColon(formatRupees(_asNum(d['amount'])))),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context).statusColon("${d['status'] ?? '—'}")),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(AppLocalizations.of(context).close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCustomer =
        ref.watch(authControllerProvider).user?.role == UserRole.customer;
    final deliveriesAsync = ref.watch(customerAwareDeliveriesProvider);

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(AppLocalizations.of(context).deliveryHistory)),
      body: deliveriesAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return DkEmpty(
              message: isCustomer
                  ? 'No deliveries in the last 30 days.\nOnce a farm accepts your request, deliveries show up here.'
                  : 'No deliveries in the last 30 days.',
              actionLabel: isCustomer ? 'Find farms' : 'Retry',
              onAction: isCustomer
                  ? () => context.push(AppRoutes.customerFindFarms)
                  : () => ref.invalidate(customerAwareDeliveriesProvider),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(customerAwareDeliveriesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final d = list[i];
                final date = _asDate(d['delivery_date']);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    tileColor: Dk.of(context).milkWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      date != null ? formatDate(date) : 'Delivery',
                      style: TextStyle(color: Dk.of(context).ink),
                    ),
                    subtitle: Text(
                      "${formatLitres(_asNum(d['quantity_litres']))} · ${d['status'] ?? '—'}",                      style: TextStyle(color: Dk.of(context).muted),
                    ),
                    trailing: Text(
                      formatRupees(_asNum(d['amount'])),
                      style: TextStyle(
                        color: Dk.of(context).ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () => _showDeliveryInfo(context, d),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DkEmpty(
          message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(customerAwareDeliveriesProvider),
        ),
      ),
    );
  }
}
