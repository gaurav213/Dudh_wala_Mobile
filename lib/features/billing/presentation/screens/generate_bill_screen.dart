import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customers/presentation/providers/customer_providers.dart';
import '../../domain/bill_preview.dart';
import '../providers/billing_providers.dart';

class GenerateBillScreen extends ConsumerStatefulWidget {
  const GenerateBillScreen({super.key, this.customerId});

  final String? customerId;

  @override
  ConsumerState<GenerateBillScreen> createState() => _GenerateBillScreenState();
}

class _GenerateBillScreenState extends ConsumerState<GenerateBillScreen> {
  String? _customerId;
  late DateTime _start;
  late DateTime _end;
  BillPreview? _preview;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _customerId = widget.customerId;
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _buildPreview() async {
    if (_customerId == null) return;
    setState(() => _busy = true);
    try {
      final preview = await ref.read(billingRepositoryProvider).preview(
            customerId: _customerId!,
            periodStart: _start,
            periodEnd: _end,
          );
      setState(() => _preview = preview);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generate() async {
    final preview = _preview;
    if (preview == null) return;
    setState(() => _busy = true);
    try {
      final number =
          'DK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final id = await ref
          .read(billingRepositoryProvider)
          .generateFromPreview(preview, billNumber: number);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).billCreated('$number'))),
        );
        context.pop(id);
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
    final l10n = AppLocalizations.of(context);
    final customers = ref.watch(customersStreamProvider);
    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(l10n.generateBill)),
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
              onChanged: (v) => setState(() => _customerId = v),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: Text(AppLocalizations.of(context).periodStart),
            subtitle: Text(formatDate(_start)),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _start,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _start = d);
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context).periodEnd),
            subtitle: Text(formatDate(_end)),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _end,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 31)),
              );
              if (d != null) setState(() => _end = d);
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : _buildPreview,
            child: Text(l10n.view),
          ),
          if (_preview != null) ...[
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).billLines('${_preview!.lines.length}')),
            Text(AppLocalizations.of(context).subtotalLabel(formatRupees(_preview!.subtotal))),
            Text("${l10n.total}: ${formatRupees(_preview!.total)}"),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _generate,
              child: Text(l10n.generateBill),
            ),
          ],
        ],
      ),
    );
  }
}
