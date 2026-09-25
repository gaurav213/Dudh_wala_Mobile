import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/sync/sync_service.dart';
import '../../data/pdf/bill_pdf_service.dart';
import '../../data/repositories/billing_repository.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncServiceProvider),
  );
});

final billPdfServiceProvider =
    Provider<BillPdfService>((ref) => BillPdfService());

final billsProvider =
    FutureProvider.family<List<Map<String, Object?>>, String?>(
        (ref, customerId) {
  return ref.watch(billingRepositoryProvider).list(customerId: customerId);
});

final outstandingProvider = FutureProvider<List<Map<String, Object?>>>((ref) {
  return ref.watch(billingRepositoryProvider).outstanding();
});

final billDetailProvider =
    FutureProvider.family<Map<String, Object?>?, String>((ref, id) {
  return ref.watch(billingRepositoryProvider).get(id);
});

final billItemsProvider =
    FutureProvider.family<List<Map<String, Object?>>, String>((ref, id) {
  return ref.watch(billingRepositoryProvider).items(id);
});
