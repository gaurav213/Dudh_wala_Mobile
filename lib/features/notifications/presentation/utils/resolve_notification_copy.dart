import '../../data/notification_catalogs.dart';

/// Prefer catalog + messageKey when present; else infer from type/title (legacy EN rows).
({String title, String body}) resolveNotificationCopy(
  String languageCode, {
  required String title,
  required String body,
  Map<String, dynamic> data = const {},
  String? type,
}) {
  final key = _resolveKey(data, title, type);
  if (key == null) {
    return (title: title, body: body);
  }
  final rawParams = data['params'];
  var params = rawParams is Map
      ? rawParams.map((k, v) => MapEntry('$k', v))
      : <String, dynamic>{};
  if (params.isEmpty) {
    final extracted = _paramsFromEnglishBody(key, body);
    if (extracted != null) params = extracted;
  }
  final lang = languageCode.toLowerCase().startsWith('hi')
      ? 'hi'
      : languageCode.toLowerCase().startsWith('mr')
          ? 'mr'
          : 'en';
  final entry =
      kNotificationCatalogs[lang]?[key] ?? kNotificationCatalogs['en']?[key];
  if (entry == null) {
    return (title: title, body: body);
  }
  return (
    title: _interpolate(entry['title'] ?? title, params),
    body: _interpolate(entry['body'] ?? body, params),
  );
}

String? _resolveKey(
  Map<String, dynamic> data,
  String title,
  String? type,
) {
  final fromData = data['messageKey'];
  if (fromData is String && fromData.isNotEmpty) return fromData;

  final en = kNotificationCatalogs['en'];
  if (en != null) {
    for (final e in en.entries) {
      if (e.value['title'] == title) return e.key;
    }
  }

  final t = (type ?? data['type'] ?? data['notificationType'])?.toString();
  if (t == null || t.isEmpty) return null;
  return _typeToKey[t];
}

/// Map API notification type → catalog key when messageKey was never stored.
const _typeToKey = <String, String>{
  'OUT_FOR_DELIVERY': 'notifOutForDelivery',
  'MILK_DELIVERED': 'notifMilkDelivered',
  'CUSTOMER_NO_MILK_TODAY': 'notifCustomerNoMilk',
  'FARM_NO_DELIVERY_TODAY': 'notifFarmNoDeliveryToday',
  'CUSTOMER_CONFIRMED_DELIVERY': 'notifCustomerConfirmed',
  'CUSTOMER_MARKED_RECEIVED': 'notifCustomerMarkedReceived',
  'DELIVERY_ISSUE_RESOLVED': 'notifIssueResolved',
  'CUSTOMER_REPORTED_NOT_RECEIVED': 'notifIssueReported',
  'WRONG_QUANTITY_REPORTED': 'notifIssueReported',
  'DELIVERY_EDITED': 'notifDeliveryEdited',
  'DELIVERY_QUANTITY_CHANGED': 'notifQuantityChanged',
  'DELIVERY_EXTRA_CHANGED': 'notifExtraChanged',
  'DELIVERY_AMOUNT_CHANGED': 'notifAmountChanged',
  'DELIVERY_EDIT_CONFIRMED': 'notifEditConfirmed',
  'DELIVERY_EDIT_FLAGGED': 'notifEditFlagged',
  'EXTRA_MILK_REQUESTED': 'notifExtraRequested',
  'EXTRA_REQUEST_ACCEPTED': 'notifExtraAccepted',
  'EXTRA_REQUEST_REJECTED': 'notifExtraRejected',
  'CASH_PAYMENT_RECORDED': 'notifCashRecorded',
  'CASH_PAYMENT_CLAIMED': 'notifCashToConfirm',
  'CASH_PAYMENT_CONFIRMED': 'notifCashConfirmed',
  'CASH_PAYMENT_REJECTED': 'notifCashRejected',
  'PRODUCT_RATE_CHANGED': 'notifRateUpdated',
  'SERVICE_REQUEST_CREATED': 'notifServiceRequestCreated',
  'SERVICE_REQUEST_ACCEPTED': 'notifServiceRequestAccepted',
  'SERVICE_REQUEST_CANCELLED': 'notifServiceRequestCancelled',
  'CUSTOMER_REVIEW_ADDED': 'notifReviewAdded',
  'CUSTOMER_REVIEW_REPORTED': 'notifReviewReported',
};

Map<String, dynamic>? _paramsFromEnglishBody(String key, String body) {
  final template = kNotificationCatalogs['en']?[key]?['body'];
  if (template == null || body.isEmpty) return null;
  return _extractParams(template, body);
}

/// Pull `{name}` / `{date}` values out of a stored English body using the EN template.
Map<String, dynamic>? _extractParams(String template, String actual) {
  final re = RegExp(r'\{(\w+)\}');
  final keys = <String>[];
  final parts = <String>[];
  var last = 0;
  for (final m in re.allMatches(template)) {
    parts.add(template.substring(last, m.start));
    keys.add(m.group(1)!);
    last = m.end;
  }
  parts.add(template.substring(last));
  if (keys.isEmpty) return actual == template ? {} : null;
  if (!actual.startsWith(parts.first)) return null;
  var rest = actual.substring(parts.first.length);
  final out = <String, dynamic>{};
  for (var i = 0; i < keys.length; i++) {
    final lit = parts[i + 1];
    if (lit.isEmpty) {
      out[keys[i]] = rest;
      rest = '';
      continue;
    }
    final idx = rest.indexOf(lit);
    if (idx < 0) return null;
    out[keys[i]] = rest.substring(0, idx);
    rest = rest.substring(idx + lit.length);
  }
  if (rest.isNotEmpty) return null;
  return out;
}

String _interpolate(
  String template,
  Map<String, dynamic> params,
) {
  return template.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) {
    final v = params[m.group(1)!];
    if (v == null) return '';
    return '$v';
  });
}
