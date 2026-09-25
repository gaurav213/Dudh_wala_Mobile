import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../providers/subscription_providers.dart';
import '../../../../l10n/app_localizations.dart';

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
        SnackBar(content: Text(AppLocalizations.of(context).customerRequired)),
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
      backgroundColor: Dk.of(context).cream,
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
            decoration: InputDecoration(labelText: AppLocalizations.of(context).quantityLitres),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: AppLocalizations.of(context).ratePerLitreInr),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _frequency,
            decoration: InputDecoration(labelText: AppLocalizations.of(context).frequency),
            items: [
              DropdownMenuItem(value: 'daily', child: Text(AppLocalizations.of(context).daily)),
              DropdownMenuItem(
                  value: 'alternate', child: Text(AppLocalizations.of(context).alternateDays)),
              DropdownMenuItem(value: 'custom', child: Text(AppLocalizations.of(context).custom)),
            ],
            onChanged: (v) => setState(() => _frequency = v ?? 'daily'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _slot,
            decoration: InputDecoration(labelText: AppLocalizations.of(context).deliverySlot),
            items: [
              DropdownMenuItem(value: 'morning', child: Text(AppLocalizations.of(context).morning)),
              DropdownMenuItem(value: 'evening', child: Text(AppLocalizations.of(context).evening)),
            ],
            onChanged: (v) => setState(() => _slot = v ?? 'morning'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? AppLocalizations.of(context).saving : 'Save subscription'),
          ),
        ],
      ),
    );
  }
}
