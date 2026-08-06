import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';

final dashboardStatsProvider = FutureProvider<Map<String, num>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.dashboardStats(day: DateTime.now());
});
