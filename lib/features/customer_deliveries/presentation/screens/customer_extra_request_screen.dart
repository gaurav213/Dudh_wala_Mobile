import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/utils/json_parsing.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/customer_deliveries_providers.dart';

/// Args passed via `context.push(AppRoutes.customerExtraRequest, extra: ...)`
/// — typically from a specific day's delivery, which is where `subscriptionId`
/// comes from.
class CustomerExtraRequestArgs {
  const CustomerExtraRequestArgs(
      {required this.subscriptionId, required this.deliveryDate});
  final String? subscriptionId;
  final String? deliveryDate;
}

class CustomerExtraRequestScreen extends ConsumerStatefulWidget {
  const CustomerExtraRequestScreen({super.key, this.args});

  final CustomerExtraRequestArgs? args;

  @override
  ConsumerState<CustomerExtraRequestScreen> createState() =>
      _CustomerExtraRequestScreenState();
}

class _CustomerExtraRequestScreenState
    extends ConsumerState<CustomerExtraRequestScreen> {
  final _quantityController = TextEditingController(text: '0.5');
  final _notesController = TextEditingController();
  late DateTime _date;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _date =
        DateTime.tryParse(widget.args?.deliveryDate ?? '') ?? DateTime.now();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subscriptionId = widget.args?.subscriptionId;
    if (subscriptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context).openDeliveryForExtraHint),
        ),
      );
      return;
    }
    final quantity = _quantityController.text.trim();
    if (double.tryParse(quantity) == null || double.parse(quantity) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).enterValidQuantity),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(customerDeliveriesApiProvider).createExtraRequest(
            subscriptionId: subscriptionId,
            deliveryDate: _date.toIso8601String().split('T').first,
            requestedQuantity: quantity,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      ref.invalidate(customerMyExtraRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).extraMilkRequestSent)),
        );
        _notesController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _cancel(String id) async {
    try {
      await ref.read(customerDeliveriesApiProvider).cancelExtraRequest(id);
      ref.invalidate(customerMyExtraRequestsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requestsAsync = ref.watch(customerMyExtraRequestsProvider);
    final hasSubscription = widget.args?.subscriptionId != null;

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(l10n.extraMilk)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Dk.of(context).milkWhite,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).requestExtraMilk,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).forDate(formatDate(_date)),
                  style: TextStyle(color: Dk.of(context).muted),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).extraQuantityLitres),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(labelText: l10n.notesOptional),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                if (!hasSubscription)
                  Text(AppLocalizations.of(context).openExtraFromDeliveryEnable,
                    style: TextStyle(color: AppColors.warning),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting || !hasSubscription ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l10n.submitRequest),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context).myRequests, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          requestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return DkEmpty(message: AppLocalizations.of(context).noExtraMilkRequestsYet);
              }
              return Column(
                children: [
                  for (final r in requests)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Dk.of(context).milkWhite,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "+${formatLitres(num.tryParse(asStringOr(r['requestedQuantity'], '0')) ?? 0)} · ${asStringOr(r['deliveryDate'])}",                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    asStringOr(r['status']),
                                    style: TextStyle(
                                        color: Dk.of(context).muted,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (asStringOr(r['status']) == 'PENDING')
                              TextButton(
                                onPressed: () => _cancel(asStringOr(r['id'])),
                                child: Text(l10n.cancel),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Text('$e', style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
