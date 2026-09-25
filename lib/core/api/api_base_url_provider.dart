import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_base_url_store.dart';

/// Live API host used by [apiClientProvider]. Seeded in bootstrap from prefs.
final apiBaseUrlProvider = StateProvider<String>(
  (ref) => ApiBaseUrlStore.current,
);
