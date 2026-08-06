import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../deliveries/presentation/providers/delivery_providers.dart';

class DeliveryCalendarScreen extends ConsumerStatefulWidget {
  const DeliveryCalendarScreen({super.key});

  @override
  ConsumerState<DeliveryCalendarScreen> createState() =>
      _DeliveryCalendarScreenState();
}

class _DeliveryCalendarScreenState
    extends ConsumerState<DeliveryCalendarScreen> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final deliveries = ref.watch(deliveriesForDateProvider(_selected));
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Delivery calendar')),
      body: Column(
        children: [
          CalendarDatePicker(
            initialDate: _selected,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            onDateChanged: (d) => setState(() => _selected = d),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                formatDate(_selected),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(
            child: deliveries.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('No deliveries'));
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final d = list[i];
                    return ListTile(
                      title: Text(d['customer_name'] as String? ?? 'Customer'),
                      subtitle: Text(
                        '${formatLitres(d['quantity_litres'] as num)} · ${d['status']}',
                      ),
                      trailing: Text(formatRupees(d['amount'] as num)),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }
}
