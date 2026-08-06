import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/sync/sync_service.dart';
import '../../data/repositories/customer_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncServiceProvider),
  );
});

final customersStreamProvider =
    StreamProvider<List<Map<String, Object?>>>((ref) {
  return ref.watch(customerRepositoryProvider).watchAll();
});

final customerDetailProvider =
    FutureProvider.family<Map<String, Object?>?, String>((ref, id) {
  return ref.watch(customerRepositoryProvider).get(id);
});
