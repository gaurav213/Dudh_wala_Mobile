import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../providers/customer_providers.dart';
import '../../../../l10n/app_localizations.dart';

class CustomersListScreen extends ConsumerWidget {
  const CustomersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersStreamProvider);
    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(AppLocalizations.of(context).customers)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.customerForm),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(AppLocalizations.of(context).add),
      ),
      body: customers.when(
        data: (list) {
          if (list.isEmpty) {
            return DkEmpty(
              message: AppLocalizations.of(context).noCustomersYet,
              actionLabel: AppLocalizations.of(context).addCustomer,
              onAction: () => context.push(AppRoutes.customerForm),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = list[i];
              return ListTile(
                tileColor: Dk.of(context).milkWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(c['name'] as String),
                subtitle: Text(formatPhoneIn(c['phone'] as String)),
                trailing: Text(
                  formatRupees(c['default_rate_per_litre'] as num),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () =>
                    context.push(AppRoutes.customerDetails(c['id'] as String)),
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
