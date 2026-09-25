import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/delivery_staff_providers.dart';

const _reasons = [
  'ENTERED_WRONG_QUANTITY',
  'CUSTOMER_CORRECTED_QUANTITY',
  'EXTRA_MILK_ENTERED_INCORRECTLY',
  'OTHER',
];

class DeliveryEditScreen extends ConsumerStatefulWidget {
  const DeliveryEditScreen({super.key, required this.deliveryId});

  final String deliveryId;

  @override
  ConsumerState<DeliveryEditScreen> createState() => _DeliveryEditScreenState();
}

class _DeliveryEditScreenState extends ConsumerState<DeliveryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _staffExtra = TextEditingController();
  final _notes = TextEditingController();
  final _otherNote = TextEditingController();
  String? _reason;
  bool _busy = false;
  bool _seeded = false;
  String _scheduled = '0';
  String _customerExtra = '0';

  @override
  void initState() {
    super.initState();
    _qty.addListener(_syncStaffExtraFromFinal);
  }

  @override
  void dispose() {
    _qty.removeListener(_syncStaffExtraFromFinal);
    _qty.dispose();
    _staffExtra.dispose();
    _notes.dispose();
    _otherNote.dispose();
    super.dispose();
  }

  void _syncStaffExtraFromFinal() {
    final finalQty = num.tryParse(_qty.text.trim()) ?? 0;
    final scheduled = num.tryParse(_scheduled) ?? 0;
    final customerExtra = num.tryParse(_customerExtra) ?? 0;
    final staffExtra = (finalQty - scheduled - customerExtra);
    final value = staffExtra > 0 ? formatQuantityString(staffExtra) : '0';
    if (_staffExtra.text != value) {
      _staffExtra.text = value;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).fieldRequired)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(deliveryStaffApiProvider).editDelivery(
            widget.deliveryId,
            finalDeliveredQuantity: _qty.text.trim(),
            deliveryNotes:
                _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            editReason: _reason!,
            editNote:
                _otherNote.text.trim().isEmpty ? null : _otherNote.text.trim(),
          );
      await refreshDeliveryStaffData(ref, deliveryId: widget.deliveryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).saved)),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(deliveryDetailProvider(widget.deliveryId));
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).edit)),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DkEmpty(message: '$e'),
        data: (d) {
          if (!_seeded) {
            _seeded = true;
            _scheduled = d.scheduledQuantity;
            _customerExtra = d.customerExtraQuantity;
            final seeded = d.finalDeliveredQuantity ?? d.quantity;
            final seededNum = num.tryParse(seeded);
            _qty.text =
                seededNum == null ? seeded : formatQuantityString(seededNum);
            _notes.text = d.deliveryNotes ?? '';
            _syncStaffExtraFromFinal();
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(d.customerName ?? AppLocalizations.of(context).customer,
                    style: Theme.of(context).textTheme.titleLarge),
                Text("${d.deliveryDate} · ${d.deliveryShift}",
                    style: TextStyle(color: Dk.of(context).muted)),
                const SizedBox(height: 12),
                _info(AppLocalizations.of(context).delivery,
                    formatLitresString(d.scheduledQuantity)),
                _info(AppLocalizations.of(context).customer,
                    formatLitresString(d.customerExtraQuantity)),
                _info(AppLocalizations.of(context).extra,
                    formatLitresString(d.staffExtraQuantity)),
                _info(
                    AppLocalizations.of(context).rate, '₹${d.ratePerLitre}/L'),
                _info(AppLocalizations.of(context).amount, '₹${d.amount}'),
                if (d.deliveredAt != null)
                  _info(AppLocalizations.of(context).delivered,
                      d.deliveredAt!.toLocal().toString()),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _qty,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).quantityL,
                    helperText: AppLocalizations.of(context).extra,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppLocalizations.of(context).required
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _staffExtra,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).extra,
                    helperText: AppLocalizations.of(context).quantityL,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).notes),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _reason,
                  decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).notes),
                  items: _reasons
                      .map((reason) => DropdownMenuItem(
                            value: reason,
                            child: Text(_reasonLabel(context, reason)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _reason = v),
                  validator: (v) =>
                      v == null ? AppLocalizations.of(context).required : null,
                ),
                if (_reason == 'OTHER') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _otherNote,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).required),
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? AppLocalizations.of(context).required
                        : null,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: Text(_busy
                      ? AppLocalizations.of(context).saving
                      : AppLocalizations.of(context).save),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
              child:
                  Text(label, style: TextStyle(color: Dk.of(context).muted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _reasonLabel(BuildContext context, String reason) {
    final l10n = AppLocalizations.of(context);
    return switch (reason) {
      'ENTERED_WRONG_QUANTITY' => l10n.quantityL,
      'CUSTOMER_CORRECTED_QUANTITY' => l10n.customer,
      'EXTRA_MILK_ENTERED_INCORRECTLY' => l10n.extra,
      _ => l10n.more,
    };
  }
}
