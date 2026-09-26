import 'package:doodh_khata_mobile/core/utils/reverse_geocode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseNominatimAddress prefers village and postcode', () {
    final picked = parseNominatimAddress({
      'display_name': '12 Lane, Kolhewadi, Sangamner, Maharashtra, 422605',
      'address': {
        'house_number': '12',
        'road': 'Lane',
        'village': 'Kolhewadi',
        'city': 'Sangamner',
        'state': 'Maharashtra',
        'postcode': '422605',
      },
    });
    expect(picked.line1, '12 Lane');
    expect(picked.area, 'Kolhewadi');
    expect(picked.city, 'Sangamner');
    expect(picked.state, 'Maharashtra');
    expect(picked.postalCode, '422605');
  });
}
