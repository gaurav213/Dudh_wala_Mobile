import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_providers.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'api_base_url_provider.dart';
import 'api_base_url_store.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokens = ref.watch(tokenStorageProvider);
  // Rebuild Dio when Settings saves a new LAN API host (USB not required).
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return ApiClient(
    tokenStorage: tokens,
    baseUrl: baseUrl.isEmpty ? ApiBaseUrlStore.current : baseUrl,
    onRefresh: () => ref.read(authControllerProvider.notifier).refreshSession(),
    onRefreshFailed: () =>
        ref.read(authControllerProvider.notifier).forceLocalLogout(),
  );
});
