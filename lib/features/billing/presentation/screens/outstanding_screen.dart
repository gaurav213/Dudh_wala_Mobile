import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/billing_providers.dart';

class OutstandingScreen extends ConsumerWidget {
  const OutstandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final outstanding = ref.watch(outstandingProvider);
    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(l10n.outstanding)),
      body: outstanding.when(
        data: (list) {
          if (list.isEmpty) {
            return DkEmpty(message: AppLocalizations.of(context).noOutstandingDues);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final b = list[i];
              return ListTile(
                tileColor: Dk.of(context).milkWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(b['customer_name'] as String? ?? l10n.customer),
                subtitle: Text(b['bill_number'] as String),
                trailing: Text(
                  formatRupees(b['due'] as num),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
                onTap: () => context.push(
                  '${AppRoutes.recordPayment}?customerId=${b['customer_id']}&billId=${b['id']}',
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
