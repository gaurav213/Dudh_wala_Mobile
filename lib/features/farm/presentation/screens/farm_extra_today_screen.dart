import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/farm_providers.dart';

/// Farm-owner view of today's deliveries that include extra milk.
class FarmExtraTodayScreen extends ConsumerWidget {
  const FarmExtraTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final metrics = ref.watch(farmTodayMetricsProvider);
    final today = ref.watch(farmDashboardProvider);

    return Scaffold(
      appBar: AppBar(title: Text("${l10n.extraMilk} · ${l10n.datesToday}")),
      body: metrics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DkEmpty(message: '$e'),
        data: (m) => FutureBuilder(
          future: ref.read(farmApiProvider).todayDeliveries(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = snap.data!.where((d) {
              final c = double.tryParse('${d['customerExtraQuantity']}') ?? 0;
              final s = double.tryParse('${d['staffExtraQuantity']}') ?? 0;
              return c > 0 || s > 0;
            }).toList();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  AppLocalizations.of(context).extraMilkColon(formatLitresString(m.totalExtraQuantity)),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  "${AppLocalizations.of(context).customerRequestedColon(formatLitresString(m.customerExtraQuantity))}\n"
                  '${AppLocalizations.of(context).staff}: ${formatLitresString(m.staffExtraQuantity)}',
                  style: TextStyle(color: Dk.of(context).muted),
                ),
                const SizedBox(height: 16),
                if (rows.isEmpty)
                  DkEmpty(message: AppLocalizations.of(context).noExtraMilkRecordedToday)
                else
                  ...rows.map((d) {
                    final name = (d['customer'] as Map?)?['name'] ??
                        d['customerName'] ??
                        l10n.customer;
                    final extra =
                        (double.tryParse('${d['customerExtraQuantity']}') ??
                                0) +
                            (double.tryParse('${d['staffExtraQuantity']}') ??
                                0);
                    final scheduled =
                        formatLitresString('${d['scheduledQuantity'] ?? 0}');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        tileColor: Dk.of(context).milkWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text("$name"),
                        subtitle: Text(
                          AppLocalizations.of(context).regularAndExtra(scheduled, formatLitres(extra)),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }),
                // Keep provider watched so refresh stays consistent.
                if (today.hasError) const SizedBox.shrink(),
              ],
            );
          },
        ),
      ),
    );
  }
}
