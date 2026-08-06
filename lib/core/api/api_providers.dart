import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_providers.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokens = ref.watch(tokenStorageProvider);
  return ApiClient(
    tokenStorage: tokens,
    onRefresh: () => ref.read(authControllerProvider.notifier).refreshSession(),
  );
});
