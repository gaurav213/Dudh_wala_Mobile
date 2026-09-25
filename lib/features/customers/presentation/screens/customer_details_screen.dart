import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/amount_text.dart';
import '../providers/customer_providers.dart';
import '../../../../l10n/app_localizations.dart';

class CustomerDetailsScreen extends ConsumerWidget {
  const CustomerDetailsScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(customerDetailProvider(customerId));
    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).customer),
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
          if (c == null) return Center(child: Text(AppLocalizations.of(context).notFound));
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
                    style: TextStyle(color: Dk.of(context).muted)),
              ],
              const SizedBox(height: 16),
              ListTile(
                tileColor: Dk.of(context).milkWhite,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                title: Text(AppLocalizations.of(context).defaultRate),
                trailing: AmountText(c['default_rate_per_litre'] as num),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => context.push(
                  '${AppRoutes.subscriptionForm}?customerId=$customerId',
                ),
                child: Text(AppLocalizations.of(context).addSubscription),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.push(
                  '${AppRoutes.generateBill}?customerId=$customerId',
                ),
                child: Text(AppLocalizations.of(context).generateBill),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.push(
                  '${AppRoutes.recordPayment}?customerId=$customerId',
                ),
                child: Text(AppLocalizations.of(context).recordPayment),
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
