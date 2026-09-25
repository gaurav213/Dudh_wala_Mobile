import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../customers/presentation/providers/customer_providers.dart';
import '../providers/billing_providers.dart';

class BillDetailsScreen extends ConsumerWidget {
  const BillDetailsScreen({super.key, required this.billId});

  final String billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final bill = ref.watch(billDetailProvider(billId));
    final items = ref.watch(billItemsProvider(billId));
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(
        title: Text("${l10n.billing} · ${l10n.details}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () async {
              final b = await ref.read(billDetailProvider(billId).future);
              if (b == null) return;
              final customer = await ref
                  .read(customerRepositoryProvider)
                  .get(b['customer_id'] as String);
              final lines = await ref.read(billItemsProvider(billId).future);
              await ref.read(billPdfServiceProvider).shareBillPdf(
                    bill: b,
                    customer: customer ??
                        {
                          'name': l10n.customer,
                          'phone': '',
                        },
                    items: lines,
                    supplierName: user?.name ?? 'Doodh Wala',
                  );
            },
          ),
        ],
      ),
      body: bill.when(
        data: (b) {
          if (b == null) return Center(child: Text(l10n.noData));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(b['bill_number'] as String,
                  style: Theme.of(context).textTheme.headlineSmall),
              Text(
                "${formatDate(b['period_start'] as DateTime)} – ${formatDate(b['period_end'] as DateTime)}",
              ),
              const SizedBox(height: 8),
              Text("${l10n.total}: ${formatRupees(b['total'] as num)}",
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                  "${l10n.collected}: ${formatRupees(b['paid_amount'] as num)}"),
              const Divider(height: 32),
              items.when(
                data: (list) => Column(
                  children: [
                    for (final item in list)
                      ListTile(
                        dense: true,
                        title: Text(item['description'] as String),
                        subtitle:
                            Text(formatDate(item['item_date'] as DateTime)),
                        trailing: Text(formatRupees(item['amount'] as num)),
                      ),
                  ],
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
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
