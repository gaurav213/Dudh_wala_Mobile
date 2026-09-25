import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/delivery_shift_helpers.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/models/marketplace_models.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/farm_providers.dart';

class FarmInvitationsScreen extends ConsumerWidget {
  const FarmInvitationsScreen({super.key});

  Future<void> _openCreateDialog(
      BuildContext context, WidgetRef ref, String farmId) async {
    final l10n = AppLocalizations.of(context);
    final products = await ref
        .read(farmProductsProvider.future)
        .catchError((_) => const <FarmProductModel>[]);
    if (!context.mounted) return;
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context).addProductBeforeInvite)),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final mobile = TextEditingController();
    final customerName = TextEditingController();
    final quantity = TextEditingController(text: '1');
    final rate =
        TextEditingController(text: products.first.currentRatePerLitre);
    final startDate = TextEditingController(
      text: DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String()
          .split('T')
          .first,
    );
    final instructions = TextEditingController();
    var productId = products.first.id;
    var shift = productDeliveryShifts(products.first.availableShifts).first;
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final product = products.firstWhere(
            (p) => p.id == productId,
            orElse: () => products.first,
          );
          final shifts = productDeliveryShifts(product.availableShifts);
          if (!shifts.contains(shift)) {
            shift = shifts.first;
          }

          return AlertDialog(
            title: Text("${l10n.invite} ${l10n.customer}"),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: mobile,
                      decoration: InputDecoration(
                          labelText: l10n.mobileNumber, prefixText: '+91 '),
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().length < 10)
                          ? 'Enter a valid number'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: customerName,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).customerNameOptional),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: productId,
                      decoration: InputDecoration(labelText: l10n.products),
                      items: products
                          .map((p) => DropdownMenuItem(
                              value: p.id, child: Text(p.name)))
                          .toList(),
                      onChanged: (v) => setState(() {
                        productId = v ?? productId;
                        final next = products.firstWhere(
                          (p) => p.id == productId,
                          orElse: () => products.first,
                        );
                        shift =
                            productDeliveryShifts(next.availableShifts).first;
                        rate.text = next.currentRatePerLitre;
                      }),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: quantity,
                      decoration: InputDecoration(labelText: l10n.quantityL),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (double.tryParse(v ?? '') == null)
                          ? l10n.enterValidQuantity
                          : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: shift,
                      decoration: InputDecoration(labelText: l10n.shift),
                      items: shifts
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(deliveryShiftLabel(s)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => shift = v ?? shift),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: rate,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).proposedRatePerL),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (double.tryParse(v ?? '') == null)
                          ? 'Enter a valid rate'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: startDate,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).preferredStartDateYmd),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: instructions,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).deliveryInstructionsOptional),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    saving ? null : () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setState(() => saving = true);
                        try {
                          await ref
                              .read(farmApiProvider)
                              .createCustomerInvitation(
                                farmId,
                                mobileNumber: mobile.text.trim(),
                                customerName: customerName.text.trim(),
                                productId: productId,
                                quantity: quantity.text.trim(),
                                deliveryShift: shift,
                                proposedRate: rate.text.trim(),
                                preferredStartDate: startDate.text.trim(),
                                deliveryInstructions: instructions.text.trim(),
                              );
                          ref.invalidate(farmCustomerInvitationsProvider);
                          invalidateFarmDashboard(ref);
                          if (dialogContext.mounted)
                            Navigator.of(dialogContext).pop();
                        } catch (e) {
                          setState(() => saving = false);
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext)
                                .showSnackBar(SnackBar(content: Text('$e')));
                          }
                        }
                      },
                child: Text(saving ? l10n.loading : l10n.invite),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _cancel(
      WidgetRef ref, BuildContext context, String farmId, String id) async {
    try {
      await ref.read(farmApiProvider).cancelCustomerInvitation(farmId, id);
      ref.invalidate(farmCustomerInvitationsProvider);
      invalidateFarmDashboard(ref);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final farmIdAsync = ref.watch(currentFarmIdProvider);
    final invitationsAsync = ref.watch(farmCustomerInvitationsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: farmIdAsync.maybeWhen(
        data: (farmId) => FloatingActionButton(
          onPressed: () => _openCreateDialog(context, ref, farmId),
          child: const Icon(Icons.add),
        ),
        orElse: () => null,
      ),
      body: invitationsAsync.when(
        data: (invitations) {
          if (invitations.isEmpty) {
            return farmIdAsync.maybeWhen(
              data: (farmId) => DkEmpty(
                message:
                    'No customer invitations yet.\nInvite a customer by mobile number to start service.',
                actionLabel: '${l10n.invite} ${l10n.customer}',
                onAction: () => _openCreateDialog(context, ref, farmId),
              ),
              orElse: () =>
                  DkEmpty(message: AppLocalizations.of(context).noCustomerInvitationsYet),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(farmCustomerInvitationsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: invitations.length,
              itemBuilder: (context, i) {
                final inv = invitations[i];
                return _InvitationCard(
                  invitation: inv,
                  onCancel: inv.isPending
                      ? () => farmIdAsync.whenData(
                            (farmId) => _cancel(ref, context, farmId, inv.id),
                          )
                      : null,
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DkEmpty(
          message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(farmCustomerInvitationsProvider),
        ),
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({required this.invitation, this.onCancel});

  final CustomerInvitationModel invitation;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Dk.of(context).milkWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  invitation.customerName ?? invitation.mobileNumber,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Chip(
                label: Text(invitation.status,
                    style: const TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
                backgroundColor: Dk.of(context).foam,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "${formatLitresString(invitation.quantity)} · ${invitation.deliveryShift} · ₹${invitation.proposedRate}/L",
            style: TextStyle(color: Dk.of(context).muted),
          ),
          Text(AppLocalizations.of(context).startingDate(invitation.preferredStartDate)),
          if (onCancel != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: onCancel,
                  child: Text("${l10n.cancel} ${l10n.invitations}")),
            ),
          ],
        ],
      ),
    );
  }
}
