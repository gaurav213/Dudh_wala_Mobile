/// Local calendar helpers. Prefer these over `toIso8601String().split('T')`
/// — that path converts to UTC and can shift the date after midnight IST.
String localDateIso([DateTime? date]) {
  final d = date ?? DateTime.now();
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Morning window for delivery UI testing: midnight–15:00 local.
bool isMorningNow([DateTime? date]) {
  final d = date ?? DateTime.now();
  return d.hour < 15;
}
