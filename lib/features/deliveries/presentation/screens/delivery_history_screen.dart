import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/delivery_providers.dart';

class DeliveryHistoryScreen extends ConsumerStatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  ConsumerState<DeliveryHistoryScreen> createState() =>
      _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends ConsumerState<DeliveryHistoryScreen> {
  late Future<List<Map<String, Object?>>> _future;

  @override
  void initState() {
    super.initState();
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 30));
    _future = Future.value(const []);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final u = ref.read(authControllerProvider).user;
      setState(() {
        _future = ref.read(deliveryRepositoryProvider).inRange(
              start,
              end,
              customerId: u?.isSupplier == true ? null : u?.id,
            );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Delivery history')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(child: Text('No deliveries in last 30 days'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final d = list[i];
              return ListTile(
                title: Text(formatDate(d['delivery_date'] as DateTime)),
                subtitle: Text(
                  '${formatLitres(d['quantity_litres'] as num)} · ${d['status']}',
                ),
                trailing: Text(formatRupees(d['amount'] as num)),
              );
            },
          );
        },
      ),
    );
  }
}
