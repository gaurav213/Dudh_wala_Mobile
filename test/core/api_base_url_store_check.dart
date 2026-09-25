import 'package:shared_preferences/shared_preferences.dart';

import 'package:doodh_khata_mobile/core/api/api_base_url_store.dart';

/// ponytail: one assert-style check; no test framework.
Future<void> main() async {
  SharedPreferences.setMockInitialValues({});
  final seeded = await ApiBaseUrlStore.load();
  assert(seeded.contains('/api/v1'), 'default URL must include /api/v1');

  final saved = await ApiBaseUrlStore.save('http://10.1.2.3:3000');
  assert(
    saved == 'http://10.1.2.3:3000/api/v1',
    'save() should append /api/v1, got $saved',
  );
  assert(ApiBaseUrlStore.current == saved, 'current should match saved');
  assert(
    !ApiBaseUrlStore.looksLikeLoopback(saved),
    'LAN IP must not look like loopback',
  );
  assert(
    ApiBaseUrlStore.looksLikeLoopback('http://127.0.0.1:3000/api/v1'),
    '127.0.0.1 should look like loopback',
  );

  // ignore: avoid_print
  print('api_base_url_store_check OK');
}
