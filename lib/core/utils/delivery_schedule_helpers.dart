import '../../l10n/app_localizations.dart';

/// Delivery frequency for milk subscriptions / service requests.
const scheduleOrder = ['EVERY_DAY', 'ALTERNATE_DAYS', 'WEEKLY'];

List<String> customerScheduleOptions() => List.unmodifiable(scheduleOrder);

String deliveryScheduleLabel(String schedule, [AppLocalizations? l10n]) {
  switch (schedule) {
    case 'EVERY_DAY':
      return l10n?.everyDay ?? 'Every day';
    case 'ALTERNATE_DAYS':
      return l10n?.alternateDays ?? 'Alternate days';
    case 'WEEKLY':
      return l10n?.onceAWeek ?? 'Once a week';
    case 'WEEKDAYS':
      return l10n?.weekdays ?? 'Weekdays';
    default:
      if (schedule.length <= 1) return schedule;
      return schedule[0] +
          schedule.substring(1).toLowerCase().replaceAll('_', ' ');
  }
}
