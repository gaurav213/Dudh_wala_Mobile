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
import '../providers/payment_providers.dart';

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  num _asNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  DateTime? _asDate(Object? value) {
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _statusLabel(Object? raw) {
    switch ('$raw') {
      case 'PENDING_CONFIRMATION':
        return 'Awaiting farm confirm';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'REJECTED':
        return 'Rejected';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return raw == null || '$raw'.isEmpty ? '—' : '$raw';
    }
  }

  Color _statusColor(BuildContext context, Object? raw) {
    switch ('$raw') {
      case 'PENDING_CONFIRMATION':
        return AppColors.warning;
      case 'CONFIRMED':
        return AppColors.leaf;
      case 'REJECTED':
        return AppColors.danger;
      default:
        return Dk.of(context).muted;
    }
  }

  void _showPaymentInfo(BuildContext context, Map<String, Object?> p) {
    final l10n = AppLocalizations.of(context);
    final paidDate = _asDate(p['paid_at']);
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
              formatRupees(_asNum(p['amount'])),
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    color: Dk.of(context).ink,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context).paidColon(paidDate != null ? formatDateTime(paidDate) : '—'),
              style: TextStyle(color: Dk.of(context).muted),
            ),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context).methodColon("${p['method'] ?? '—'}")),
            const SizedBox(height: 4),
            Text(
              "${l10n.status}: ${_statusLabel(p['status'])}",              style: TextStyle(color: _statusColor(context, p['status'])),
            ),
            if ((p['notes'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text("${l10n.notes}: ${p['notes']}"),
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

  Future<void> _refresh(
      WidgetRef ref, bool isCustomer, String? customerId) async {
    if (isCustomer) {
      ref.invalidate(customerAwarePaymentsProvider(customerId));
      try {
        await ref.read(customerAwarePaymentsProvider(customerId).future);
      } catch (_) {}
    } else {
      ref.invalidate(paymentsProvider(customerId));
      try {
        await ref.read(paymentsProvider(customerId).future);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).user;
    final customerId = user?.isSupplier == true ? null : user?.id;
    final isCustomer = user?.role == UserRole.customer;
    final payments = isCustomer
        ? ref.watch(customerAwarePaymentsProvider(customerId))
        : ref.watch(paymentsProvider(customerId));
    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(l10n.payments)),
      body: RefreshIndicator(
        color: AppColors.leaf,
        onRefresh: () => _refresh(ref, isCustomer, customerId),
        child: payments.when(
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  DkEmpty(
                    message: isCustomer
                        ? 'No payments yet.\nReport cash from Bills, or wait until your farm records a payment.'
                        : 'No payments yet.',
                    actionLabel: isCustomer ? l10n.bills : null,
                    onAction: isCustomer
                        ? () => context.push(AppRoutes.customerBilling)
                        : null,
                  ),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final p = list[i];
                final paidDate = _asDate(p['paid_at']);
                final status = p['status'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    tileColor: Dk.of(context).milkWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      formatRupees(_asNum(p['amount'])),
                      style: TextStyle(color: Dk.of(context).ink),
                    ),
                    subtitle: Text(
                      "${paidDate != null ? formatDateTime(paidDate) : '—'} · ${p['method'] ?? ''}\n${_statusLabel(status)}",
                      style: TextStyle(color: Dk.of(context).muted),
                    ),
                    isThreeLine: true,
                    trailing: Icon(
                      Icons.chevron_right,
                      color: _statusColor(context, status),
                    ),
                    onTap: () => _showPaymentInfo(context, p),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 80),
              DkEmpty(
                message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
                actionLabel: l10n.retry,
                onAction: () => _refresh(ref, isCustomer, customerId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
