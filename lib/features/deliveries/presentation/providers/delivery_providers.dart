import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/sync/sync_service.dart';
import '../../data/repositories/delivery_repository.dart';

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncServiceProvider),
  );
});

final todaysDeliveriesProvider =
    StreamProvider<List<Map<String, Object?>>>((ref) {
  final today = DateTime.now();
  return ref.watch(deliveryRepositoryProvider).watchForDate(today);
});

final deliveriesForDateProvider =
    StreamProvider.family<List<Map<String, Object?>>, DateTime>((ref, date) {
  return ref.watch(deliveryRepositoryProvider).watchForDate(date);
});
