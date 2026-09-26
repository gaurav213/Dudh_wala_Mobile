import 'package:dio/dio.dart';

class PickedAddress {
  const PickedAddress({
    this.line1,
    this.area,
    this.city,
    this.state,
    this.postalCode,
  });

  final String? line1;
  final String? area;
  final String? city;
  final String? state;
  final String? postalCode;

  bool get hasAnything =>
      (line1 ?? area ?? city ?? state ?? postalCode)?.isNotEmpty == true;
}

String? _first(Map<String, dynamic> address, List<String> keys) {
  for (final key in keys) {
    final value = address[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

/// Maps Nominatim `address` + `display_name` into farm registration fields.
PickedAddress parseNominatimAddress(Map<String, dynamic> json) {
  final raw = json['address'];
  final address = raw is Map
      ? Map<String, dynamic>.from(raw)
      : const <String, dynamic>{};
  final display = json['display_name'];
  final roadBits = [
    _first(address, const ['house_number']),
    _first(address, const ['road', 'pedestrian', 'path']),
  ].whereType<String>().toList();
  final line1 = roadBits.isNotEmpty
      ? roadBits.join(' ')
      : (display is String && display.trim().isNotEmpty
          ? display.split(',').first.trim()
          : null);

  return PickedAddress(
    line1: line1,
    area: _first(address, const [
      'village',
      'hamlet',
      'suburb',
      'neighbourhood',
      'city_district',
      'quarter',
    ]),
    city: _first(address, const [
      'city',
      'town',
      'municipality',
      'county',
    ]),
    state: _first(address, const ['state']),
    postalCode: _first(address, const ['postcode']),
  );
}

Future<PickedAddress> reverseGeocode({
  required double latitude,
  required double longitude,
}) async {
  final res = await Dio().get<Map<String, dynamic>>(
    'https://nominatim.openstreetmap.org/reverse',
    queryParameters: {
      'lat': latitude,
      'lon': longitude,
      'format': 'jsonv2',
      'addressdetails': 1,
    },
    options: Options(
      headers: {
        'User-Agent': 'DoodhWala/1.0 (farm-registration)',
        'Accept-Language': 'en',
      },
    ),
  );
  return parseNominatimAddress(res.data ?? const {});
}
