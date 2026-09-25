import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/sync/sync_service.dart';
import '../../data/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncServiceProvider),
  );
});

final subscriptionsProvider =
    FutureProvider.family<List<Map<String, Object?>>, String?>(
        (ref, customerId) {
  return ref.watch(subscriptionRepositoryProvider).list(customerId: customerId);
});
