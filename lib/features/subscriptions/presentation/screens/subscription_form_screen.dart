import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../providers/subscription_providers.dart';

class SubscriptionFormScreen extends ConsumerStatefulWidget {
  const SubscriptionFormScreen({
    super.key,
    this.subscriptionId,
    this.customerId,
  });

  final String? subscriptionId;
  final String? customerId;

  @override
  ConsumerState<SubscriptionFormScreen> createState() =>
      _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState
    extends ConsumerState<SubscriptionFormScreen> {
  final _qty = TextEditingController(text: '1');
  final _rate = TextEditingController(text: '60');
  String _frequency = 'daily';
  String _slot = 'morning';
  bool _saving = false;

  @override
  void dispose() {
    _qty.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final customerId = widget.customerId;
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer is required')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      if (widget.subscriptionId == null) {
        await repo.create({
          'customer_id': customerId,
          'quantity_litres': double.parse(_qty.text),
          'rate_per_litre': double.parse(_rate.text),
          'frequency': _frequency,
          'delivery_slot': _slot,
          'start_date': DateTime.now(),
        });
      } else {
        await repo.update(widget.subscriptionId!, {
          'quantity_litres': double.parse(_qty.text),
          'rate_per_litre': double.parse(_rate.text),
          'frequency': _frequency,
          'delivery_slot': _slot,
        });
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          widget.subscriptionId == null
              ? 'New subscription'
              : 'Edit subscription',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _qty,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Quantity (litres)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Rate / litre (₹)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _frequency,
            decoration: const InputDecoration(labelText: 'Frequency'),
            items: const [
              DropdownMenuItem(value: 'daily', child: Text('Daily')),
              DropdownMenuItem(value: 'alternate', child: Text('Alternate days')),
              DropdownMenuItem(value: 'custom', child: Text('Custom')),
            ],
            onChanged: (v) => setState(() => _frequency = v ?? 'daily'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _slot,
            decoration: const InputDecoration(labelText: 'Delivery slot'),
            items: const [
              DropdownMenuItem(value: 'morning', child: Text('Morning')),
              DropdownMenuItem(value: 'evening', child: Text('Evening')),
            ],
            onChanged: (v) => setState(() => _slot = v ?? 'morning'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save subscription'),
          ),
        ],
      ),
    );
  }
}
