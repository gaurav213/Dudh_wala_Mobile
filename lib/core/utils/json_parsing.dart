/// Small helpers for defensively parsing loosely-typed JSON coming from the
/// backend (decimal columns are serialized as strings, dates as ISO text).
library;

DateTime? parseDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

String asStringOr(Object? value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

String? asStringOrNull(Object? value) {
  if (value == null) return null;
  return value.toString();
}

bool asBool(Object? value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  return value.toString().toLowerCase() == 'true';
}

int asInt(Object? value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

List<String> asStringList(Object? value) {
  if (value is List) return value.map((e) => e.toString()).toList();
  return const [];
}

List<Map<String, dynamic>> asMapList(Object? value) {
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().toList();
  }
  return const [];
}
