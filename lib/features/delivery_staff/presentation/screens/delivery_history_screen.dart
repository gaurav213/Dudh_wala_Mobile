import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/delivery_staff_providers.dart';
import '../widgets/delivery_tile.dart';

/// Last 14 days of deliveries, grouped by date (most recent first).
class DeliveryHistoryScreen extends ConsumerWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(deliveryHistoryProvider);

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(AppLocalizations.of(context).history)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(deliveryHistoryProvider),
        child: historyAsync.when(
          data: (deliveries) {
            if (deliveries.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: 80),
                  DkEmpty(message: AppLocalizations.of(context).emptyDefault),
                ],
              );
            }
            final byDate = <String, List<dynamic>>{};
            for (final d in deliveries) {
              byDate.putIfAbsent(d.deliveryDate, () => []).add(d);
            }
            final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dates.length,
              itemBuilder: (context, i) {
                final date = dates[i];
                final items = byDate[date]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(
                        date,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Dk.of(context).muted),
                      ),
                    ),
                    for (final d in items) DeliveryTile(delivery: d),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 80),
              DkEmpty(
                message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
                actionLabel: AppLocalizations.of(context).retry,
                onAction: () => ref.invalidate(deliveryHistoryProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
