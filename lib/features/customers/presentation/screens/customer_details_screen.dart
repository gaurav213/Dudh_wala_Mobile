import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/amount_text.dart';
import '../providers/customer_providers.dart';

class CustomerDetailsScreen extends ConsumerWidget {
  const CustomerDetailsScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(customerDetailProvider(customerId));
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Customer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push(AppRoutes.customerFormWithId(customerId)),
          ),
        ],
      ),
      body: customer.when(
        data: (c) {
          if (c == null) return const Center(child: Text('Not found'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(c['name'] as String,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(formatPhoneIn(c['phone'] as String)),
              if (c['address'] != null) ...[
                const SizedBox(height: 8),
                Text(c['address'] as String,
                    style: TextStyle(color: AppColors.muted)),
              ],
              const SizedBox(height: 16),
              ListTile(
                tileColor: AppColors.milkWhite,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                title: const Text('Default rate'),
                trailing: AmountText(c['default_rate_per_litre'] as num),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => context.push(
                  '${AppRoutes.subscriptionForm}?customerId=$customerId',
                ),
                child: const Text('Add subscription'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.push(
                  '${AppRoutes.generateBill}?customerId=$customerId',
                ),
                child: const Text('Generate bill'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.push(
                  '${AppRoutes.recordPayment}?customerId=$customerId',
                ),
                child: const Text('Record payment'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
