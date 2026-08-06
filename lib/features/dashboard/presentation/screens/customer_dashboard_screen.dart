import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../billing/presentation/providers/billing_providers.dart';
import '../../../deliveries/presentation/providers/delivery_providers.dart';

class CustomerDashboardScreen extends ConsumerWidget {
  const CustomerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final deliveries = ref.watch(todaysDeliveriesProvider);
    final bills = ref.watch(billsProvider(user?.id));

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(user?.name ?? 'My milk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.customerProfile),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Today · ${formatDate(DateTime.now())}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          deliveries.when(
            data: (list) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.milkWhite,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                list.isEmpty
                    ? 'No delivery scheduled today'
                    : '${list.length} delivery(s) today · ${formatLitres(list.fold<num>(0, (a, d) => a + (d['quantity_litres'] as num)))}',
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 20),
          ListTile(
            tileColor: AppColors.milkWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Delivery calendar'),
            onTap: () => context.push(AppRoutes.customerCalendar),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: AppColors.milkWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.history),
            title: const Text('Delivery history'),
            onTap: () => context.push(AppRoutes.customerHistory),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: AppColors.milkWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Bills'),
            subtitle: bills.when(
              data: (b) => Text('${b.length} bill(s)'),
              loading: () => null,
              error: (_, __) => null,
            ),
            onTap: () => context.push(AppRoutes.customerBills),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: AppColors.milkWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Payments'),
            onTap: () => context.push(AppRoutes.customerPayments),
          ),
        ],
      ),
    );
  }
}
