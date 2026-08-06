import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../providers/delivery_providers.dart';

class TodaysDeliveriesScreen extends ConsumerWidget {
  const TodaysDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveries = ref.watch(todaysDeliveriesProvider);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text("Today's deliveries")),
      body: deliveries.when(
        data: (list) {
          if (list.isEmpty) {
            return const DkEmpty(message: 'No deliveries for today yet.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = list[i];
              final status = d['status'] as String;
              return ListTile(
                tileColor: AppColors.milkWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(d['customer_name'] as String? ?? 'Customer'),
                subtitle: Text(
                  '${formatLitres(d['quantity_litres'] as num)} · ${d['slot']}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AmountText(d['amount'] as num),
                    Text(status, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                onTap: () async {
                  final next = status == 'delivered' ? 'pending' : 'delivered';
                  await ref.read(deliveryRepositoryProvider).markStatus(
                        d['id'] as String,
                        status: next,
                      );
                },
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
