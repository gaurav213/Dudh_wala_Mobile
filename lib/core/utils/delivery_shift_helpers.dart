import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

const deliveryShiftOrder = ['MORNING', 'AFTERNOON', 'EVENING'];

List<String> sortDeliveryShifts(Iterable<String> shifts) {
  final list = shifts.toList();
  list.sort(
    (a, b) =>
        deliveryShiftOrder.indexOf(a).compareTo(deliveryShiftOrder.indexOf(b)),
  );
  return list;
}

String deliveryShiftLabel(String shift, [AppLocalizations? l10n]) {
  switch (shift) {
    case 'MORNING':
      return l10n?.morning ?? 'Morning';
    case 'AFTERNOON':
      return l10n?.afternoon ?? 'Afternoon';
    case 'EVENING':
      return l10n?.evening ?? 'Evening';
    default:
      if (shift.length <= 1) return shift;
      return '${shift[0]}${shift.substring(1).toLowerCase()}';
  }
}

IconData deliveryShiftIcon(String shift) {
  switch (shift) {
    case 'EVENING':
      return Icons.nights_stay_outlined;
    case 'AFTERNOON':
      return Icons.wb_twilight_outlined;
    default:
      return Icons.wb_sunny_outlined;
  }
}

List<String> productDeliveryShifts(List<String> available) {
  if (available.isEmpty) return const ['MORNING'];
  return sortDeliveryShifts(available);
}

String localizedMilkType(AppLocalizations l10n, String? type) {
  switch (type?.toUpperCase()) {
    case null:
    case '':
      return l10n.anyFilter;
    case 'COW':
      return l10n.cow;
    case 'BUFFALO':
      return l10n.buffalo;
    case 'MIXED':
      return l10n.mixed;
    case 'TONED':
      return l10n.toned;
    case 'OTHER':
      return l10n.milkTypeOther;
    default:
      if (type!.length <= 1) return type;
      return '${type[0]}${type.substring(1).toLowerCase()}';
  }
}
