import '../../l10n/app_localizations.dart';

/// Map API delivery status enums to UI copy.
String localizedDeliveryStatus(AppLocalizations l10n, String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return l10n.pending;
    case 'OUT_FOR_DELIVERY':
      return l10n.outForDelivery;
    case 'DELIVERED':
      return l10n.delivered;
    case 'SKIPPED':
      return l10n.skipped;
    case 'FAILED':
      return l10n.failed;
    case 'CANCELLED':
      return l10n.cancelled;
    case 'DISPUTED':
      return l10n.disputed;
    default:
      return status.replaceAll('_', ' ');
  }
}

/// Map API shift enums (MORNING / EVENING) to UI copy.
String localizedDeliveryShift(AppLocalizations l10n, String shift) {
  switch (shift.toUpperCase()) {
    case 'MORNING':
      return l10n.morning;
    case 'AFTERNOON':
      return l10n.afternoon;
    case 'EVENING':
      return l10n.evening;
    default:
      if (shift.isEmpty) return shift;
      return shift[0] +
          shift.substring(1).toLowerCase().replaceAll('_', ' ');
  }
}
