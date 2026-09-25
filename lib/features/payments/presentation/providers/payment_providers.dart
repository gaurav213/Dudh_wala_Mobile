import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/sync/sync_service.dart';
import '../../data/repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncServiceProvider),
  );
});

final paymentsProvider =
    FutureProvider.family<List<Map<String, Object?>>, String?>(
        (ref, customerId) {
  return ref.watch(paymentRepositoryProvider).list(customerId: customerId);
});
