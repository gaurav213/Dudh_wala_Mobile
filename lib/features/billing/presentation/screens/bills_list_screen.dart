import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../providers/billing_providers.dart';

class BillsListScreen extends ConsumerWidget {
  const BillsListScreen({super.key, this.customerId});

  final String? customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(billsProvider(customerId));
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Bills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.generateBill),
          ),
        ],
      ),
      body: bills.when(
        data: (list) {
          if (list.isEmpty) {
            return DkEmpty(
              message: 'No bills yet.',
              actionLabel: 'Generate bill',
              onAction: () => context.push(AppRoutes.generateBill),
            );
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
                title: Text(b['bill_number'] as String),
                subtitle: Text(
                  '${formatDate(b['period_start'] as DateTime)} – ${formatDate(b['period_end'] as DateTime)}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatRupees(b['total'] as num),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(b['status'] as String,
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
                onTap: () =>
                    context.push(AppRoutes.billDetails(b['id'] as String)),
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
