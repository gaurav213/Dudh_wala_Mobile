import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/payment_providers.dart';

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final customerId = user?.isSupplier == true ? null : user?.id;
    final payments = ref.watch(paymentsProvider(customerId));
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Payment history')),
      body: payments.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No payments yet'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final p = list[i];
              return ListTile(
                title: Text(formatRupees(p['amount'] as num)),
                subtitle: Text(
                  '${formatDateTime(p['paid_at'] as DateTime)} · ${p['method']}',
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
