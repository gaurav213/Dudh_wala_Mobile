import 'package:doodh_khata_mobile/core/utils/location_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocationHelpers.formatDistance', () {
    test('uses meters under 1 km', () {
      expect(LocationHelpers.formatDistance(420), '420 m');
    });

    test('uses kilometers at or above 1 km', () {
      expect(LocationHelpers.formatDistance(1400), '1.4 km');
    });

    test('handles missing distance', () {
      expect(LocationHelpers.formatDistance(null), 'Location unavailable');
    });
  });

  group('nearest-first local sort', () {
    test('orders by distance and puts missing coords last', () {
      final stops = [
        _Stop('Far', 1400),
        _Stop('NoPin', null),
        _Stop('Near', 400),
      ];
      stops.sort((a, b) {
        final aHas = a.meters != null ? 0 : 1;
        final bHas = b.meters != null ? 0 : 1;
        if (aHas != bHas) return aHas - bHas;
        if (a.meters != null && b.meters != null) {
          return a.meters!.compareTo(b.meters!);
        }
        return a.name.compareTo(b.name);
      });
      expect(stops.map((s) => s.name).toList(), ['Near', 'Far', 'NoPin']);
    });
  });
}

class _Stop {
  _Stop(this.name, this.meters);
  final String name;
  final double? meters;
}
