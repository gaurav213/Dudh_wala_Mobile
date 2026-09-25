import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customers/presentation/providers/customer_providers.dart';
import '../providers/payment_providers.dart';

class RecordPaymentScreen extends ConsumerStatefulWidget {
  const RecordPaymentScreen({super.key, this.customerId, this.billId});

  final String? customerId;
  final String? billId;

  @override
  ConsumerState<RecordPaymentScreen> createState() =>
      _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  String? _customerId;
  final _amount = TextEditingController();
  String _method = 'cash';
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _customerId = widget.customerId;
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_customerId == null) return;
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).enterValidAmount),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(paymentRepositoryProvider).record(
            customerId: _customerId!,
            billId: widget.billId,
            amount: amount,
            method: _method,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final customers = ref.watch(customersStreamProvider);
    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(l10n.recordCash)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          customers.when(
            data: (list) => DropdownButtonFormField<String>(
              value: _customerId,
              decoration: InputDecoration(labelText: l10n.customer),
              items: [
                for (final c in list)
                  DropdownMenuItem(
                    value: c['id'] as String,
                    child: Text(c['name'] as String),
                  ),
              ],
              onChanged: widget.customerId == null
                  ? (v) => setState(() => _customerId = v)
                  : null,
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.amountInr),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _method,
            decoration: InputDecoration(labelText: AppLocalizations.of(context).method),
            items: [
              DropdownMenuItem(value: 'cash', child: Text(AppLocalizations.of(context).cash)),
              DropdownMenuItem(value: 'upi', child: Text(AppLocalizations.of(context).upi)),
              DropdownMenuItem(value: 'bank', child: Text(AppLocalizations.of(context).bankTransfer)),
            ],
            onChanged: (v) => setState(() => _method = v ?? 'cash'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: InputDecoration(labelText: l10n.notes),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? l10n.saving : l10n.save),
          ),
        ],
      ),
    );
  }
}
