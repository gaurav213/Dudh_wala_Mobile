import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/utils/launch_helpers.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/farm_providers.dart';

class FarmStaffTodayScreen extends ConsumerWidget {
  const FarmStaffTodayScreen({
    super.key,
    required this.staffUserId,
    this.section = 'all',
  });

  final String staffUserId;
  final String section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(farmStaffTodayProvider((staffUserId, section)));
    final title = switch (section) {
      'pending' => '${l10n.pending} ${l10n.deliveries}',
      'extra' => '${l10n.extraMilk} · ${l10n.datesToday}',
      'edited' => '${l10n.edit} ${l10n.deliveries}',
      _ => l10n.farmAajKiList,
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DkEmpty(
          message: '$e',
          actionLabel: l10n.retry,
          onAction: () =>
              ref.invalidate(farmStaffTodayProvider((staffUserId, section))),
        ),
        data: (data) {
          if (data.deliveries.isEmpty) {
            return DkEmpty(message: AppLocalizations.of(context).noDeliveriesInList);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (section == 'extra')
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    AppLocalizations.of(context).totalExtraDelivered(formatLitresString(data.totalExtra)),
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              if (section == 'pending')
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text("${data.deliveries.length} ${l10n.remaining}"),
                ),
              ...data.deliveries.map((row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    tileColor: Dk.of(context).milkWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(row.customerName ?? l10n.customer),
                    subtitle: Text(
                      [
                        if (row.address != null) row.address!,
                        'Qty ${formatLitresString(row.scheduledQuantity)}',
                        if (double.tryParse(row.extraQuantity) != null &&
                            double.parse(row.extraQuantity) > 0)
                          'Extra ${formatLitresString(row.extraQuantity)}',
                        row.status,
                        if (row.isEdited) 'Edited',
                      ].join('\n'),
                    ),
                    isThreeLine: true,
                    onTap: () => context
                        .push(AppRoutes.farmTodayCustomer(row.customerId)),
                    trailing: row.mobileNumber == null
                        ? const Icon(Icons.chevron_right)
                        : IconButton(
                            icon: const Icon(Icons.call),
                            onPressed: () => LaunchHelpers.call(
                              context,
                              row.mobileNumber,
                            ),
                          ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
