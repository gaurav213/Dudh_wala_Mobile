import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../providers/billing_providers.dart';

class OutstandingScreen extends ConsumerWidget {
  const OutstandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outstanding = ref.watch(outstandingProvider);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Outstanding')),
      body: outstanding.when(
        data: (list) {
          if (list.isEmpty) {
            return const DkEmpty(message: 'No outstanding dues. Nice!');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final b = list[i];
              return ListTile(
                tileColor: AppColors.milkWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(b['customer_name'] as String? ?? 'Customer'),
                subtitle: Text(b['bill_number'] as String),
                trailing: Text(
                  formatRupees(b['due'] as num),
                  style: const TextStyle(
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
