import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../billing/presentation/providers/billing_providers.dart';
import '../../../deliveries/presentation/providers/delivery_providers.dart';
import '../../../payments/presentation/providers/payment_providers.dart';
import '../../data/customer_ledger_api.dart';

final customerLedgerApiProvider = Provider<CustomerLedgerApi>((ref) {
  return CustomerLedgerApi(ref.watch(apiClientProvider));
});

/// Bills for the signed-in user. Customers use REST `/me/bills`; farm owners use SQLite.
final customerAwareBillsProvider =
    FutureProvider.family<List<Map<String, Object?>>, String?>(
        (ref, customerId) async {
  final user = ref.watch(authControllerProvider).user;
  if (user?.role == UserRole.customer) {
    return ref.watch(customerLedgerApiProvider).bills();
  }
  return ref.watch(billsProvider(customerId).future);
});

final customerAwarePaymentsProvider =
    FutureProvider.autoDispose
        .family<List<Map<String, Object?>>, String?>((ref, customerId) async {
  final user = ref.watch(authControllerProvider).user;
  if (user?.role == UserRole.customer) {
    return ref.watch(customerLedgerApiProvider).payments();
  }
  return ref.watch(paymentsProvider(customerId).future);
});

final customerAwareDeliveriesProvider =
    FutureProvider<List<Map<String, Object?>>>((ref) async {
  final user = ref.watch(authControllerProvider).user;
  if (user?.role == UserRole.customer) {
    return ref.watch(customerLedgerApiProvider).deliveries();
  }
  final end = DateTime.now();
  final start = end.subtract(const Duration(days: 30));
  return ref.read(deliveryRepositoryProvider).inRange(
        start,
        end,
        customerId: user?.isSupplier == true ? null : user?.id,
      );
});

final customerAwareDeliveriesForDateProvider =
    FutureProvider.family<List<Map<String, Object?>>, DateTime>(
        (ref, date) async {
  final user = ref.watch(authControllerProvider).user;
  if (user?.role == UserRole.customer) {
    final day = localDateIso(date);
    final all = await ref.watch(customerLedgerApiProvider).deliveries(
          dateFrom: day,
          dateTo: day,
          limit: 100,
        );
    return all.where((d) {
      final raw = d['delivery_date'];
      if (raw is DateTime) {
        return raw.year == date.year &&
            raw.month == date.month &&
            raw.day == date.day;
      }
      if (raw is String) return raw.startsWith(day);
      return false;
    }).toList();
  }
  return ref.watch(deliveriesForDateProvider(date).future);
});
