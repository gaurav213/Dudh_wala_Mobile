import 'package:doodh_khata_mobile/app/branding/app_brand.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppBrand public name is Doodh Wala', () {
    expect(AppBrand.name, 'Doodh Wala');
    expect(AppBrand.tagline, contains('Fresh milk'));
    expect(AppBrand.logoCompact, contains('logo_mark'));
  });
}
