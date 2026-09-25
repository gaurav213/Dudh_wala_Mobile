import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/farm_providers.dart';

class FarmEditedDeliveriesScreen extends ConsumerWidget {
  const FarmEditedDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(farmEditedTodayProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text("${l10n.edit} ${l10n.deliveries} · ${l10n.datesToday}"),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DkEmpty(
          message: '$e',
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(farmEditedTodayProvider),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return DkEmpty(message: AppLocalizations.of(context).noEditedDeliveriesToday);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(farmEditedTodayProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final d = rows[i];
                final name = (d['customer'] as Map?)?['name'] ??
                    d['customerName'] ??
                    l10n.customer;
                final qty = formatLitresString(
                  '${d['finalDeliveredQuantity'] ?? d['quantity'] ?? ''}',
                );
                final review = d['editReviewStatus'] ?? 'NOT_REQUIRED';
                return ListTile(
                  tileColor: Dk.of(context).milkWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text("$name"),
                  subtitle: Text(
                    "$qty · ${d['status'] ?? ''}"
                    '${review == 'PENDING_REVIEW' ? ' · Review required' : ' · Edited'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    AppRoutes.farmDeliveryEditReview('${d['id']}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
