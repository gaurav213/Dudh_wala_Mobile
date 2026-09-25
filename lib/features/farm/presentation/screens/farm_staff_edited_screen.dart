import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/farm_providers.dart';

class FarmStaffEditedScreen extends ConsumerWidget {
  const FarmStaffEditedScreen({super.key, required this.staffUserId});

  final String staffUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text("${l10n.edit} ${l10n.deliveries}")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: () async {
          final farmId = await ref.read(currentFarmIdProvider.future);
          return ref
              .read(farmApiProvider)
              .staffEditedDeliveries(farmId, staffUserId);
        }(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return DkEmpty(message: '${snap.error}');
          }
          final data = snap.data ?? const {};
          final stats = data['stats'] as Map? ?? const {};
          final items = (data['items'] as List? ?? const []).whereType<Map>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                "Today: ${stats['editedToday'] ?? 0} · "
                'Week: ${stats['editedThisWeek'] ?? 0} · '
                'Month: ${stats['editedThisMonth'] ?? 0}',
                style: TextStyle(color: Dk.of(context).muted),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                DkEmpty(
                    message: AppLocalizations.of(context).noEditedDeliveriesForStaff)
              else
                ...items.map((h) {
                  final delivery = h['delivery'] as Map? ?? const {};
                  final customer = delivery['customer'] as Map? ?? const {};
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      tileColor: Dk.of(context).milkWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text("${customer['name'] ?? l10n.customer}"),
                      subtitle: Text(
                        "${formatLitresString('${h['previousQuantity']}')} → "
                        '${formatLitresString('${h['newQuantity']}')}\n'
                        '${'${h['editReason'] ?? ''}'.replaceAll('_', ' ')}',
                      ),
                      isThreeLine: true,
                      onTap: () => context.push(
                        AppRoutes.farmDeliveryEditReview('${delivery['id']}'),
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
