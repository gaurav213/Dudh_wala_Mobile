import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import 'bills_list_screen.dart';

/// Customer-scoped bills list (read-only list of own bills).
class CustomerBillsScreen extends ConsumerWidget {
  const CustomerBillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authControllerProvider).user?.id;
    return BillsListScreen(customerId: userId);
  }
}
