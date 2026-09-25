import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../customer_marketplace/presentation/providers/customer_ledger_providers.dart';
import '../providers/billing_providers.dart';

class BillsListScreen extends ConsumerWidget {
  const BillsListScreen({
    super.key,
    this.customerId,
    this.readOnly = false,
  });

  final String? customerId;
  final bool readOnly;

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

  void _showBillInfo(BuildContext context, Map<String, Object?> b) {
    final l10n = AppLocalizations.of(context);
    final start = _asDate(b['period_start']);
    final end = _asDate(b['period_end']);
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
              (b['bill_number'] as String?) ?? l10n.billing,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    color: Dk.of(context).ink,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).periodColon(start != null && end != null ? '${formatDate(start)} – ${formatDate(end)}' : AppLocalizations.of(context).periodUnavailable),
              style: TextStyle(color: Dk.of(context).muted),
            ),
            const SizedBox(height: 6),
            Text(
              "${l10n.total}: ${formatRupees(_asNum(b['total']))}",              style: TextStyle(
                color: Dk.of(context).ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "${l10n.status}: ${(b['status'] as String?) ?? '—'}",              style: TextStyle(color: Dk.of(context).muted),
            ),
            if (b['notes'] != null && '${b['notes']}'.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text("${l10n.notes}: ${b['notes']}",                  style: TextStyle(color: Dk.of(context).muted)),
            ],
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isCustomer =
        ref.watch(authControllerProvider).user?.role == UserRole.customer;
    final bills = isCustomer
        ? ref.watch(customerAwareBillsProvider(customerId))
        : ref.watch(billsProvider(customerId));
    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(
        title: Text(l10n.bills),
        actions: [
          if (!readOnly)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push(AppRoutes.generateBill),
            ),
        ],
      ),
      body: bills.when(
        data: (list) {
          if (list.isEmpty) {
            return DkEmpty(
              message: readOnly
                  ? 'No delivered milk billed yet.\nYour open month bill appears after the first delivery — pay anytime.'
                  : 'No bills yet.',
              actionLabel: readOnly ? l10n.billing : l10n.generateBill,
              onAction: readOnly
                  ? () => context.push(AppRoutes.customerBilling)
                  : () => context.push(AppRoutes.generateBill),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final b = list[i];
              final start = _asDate(b['period_start']);
              final end = _asDate(b['period_end']);
              return ListTile(
                tileColor: Dk.of(context).milkWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(
                  (b['bill_number'] as String?) ?? l10n.billing,
                  style: TextStyle(color: Dk.of(context).ink),
                ),
                subtitle: Text(
                  start != null && end != null
                      ? '${formatDate(start)} – ${formatDate(end)}'
                      : 'Period unavailable',
                  style: TextStyle(color: Dk.of(context).muted),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatRupees(_asNum(b['total'])),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Dk.of(context).ink,
                      ),
                    ),
                    Text(
                      (b['status'] as String?) ?? '—',
                      style:
                          TextStyle(fontSize: 12, color: Dk.of(context).muted),
                    ),
                  ],
                ),
                onTap: () {
                  if (readOnly) {
                    _showBillInfo(context, b);
                    return;
                  }
                  final id = b['id'] as String?;
                  if (id == null) return;
                  context.push(AppRoutes.billDetails(id));
                },
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
              ref.invalidate(customerAwareBillsProvider(customerId));
            } else {
              ref.invalidate(billsProvider(customerId));
            }
          },
        ),
      ),
    );
  }
}
