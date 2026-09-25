import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/delivery_shift_helpers.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/models/marketplace_models.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/farm_providers.dart';

const _milkTypes = ['COW', 'BUFFALO', 'MIXED', 'TONED', 'OTHER'];

class FarmProductsScreen extends ConsumerWidget {
  const FarmProductsScreen({super.key});

  Future<void> _openAddDialog(
      BuildContext context, WidgetRef ref, String farmId) async {
    final l10n = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final description = TextEditingController();
    final rate = TextEditingController();
    final minQty = TextEditingController(text: '0.5');
    final maxQty = TextEditingController();
    var milkType = _milkTypes.first;
    final selectedShifts = <String>{'MORNING'};
    var isAvailable = true;
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text("${l10n.add} ${l10n.products}"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: InputDecoration(labelText: l10n.name),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.required : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: milkType,
                    decoration: InputDecoration(labelText: l10n.milkType),
                    items: _milkTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => milkType = v ?? milkType),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: description,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).descriptionOptional),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: rate,
                    decoration: InputDecoration(labelText: l10n.ratePerLitre),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (double.tryParse(v ?? '') == null)
                        ? l10n.enterValidAmount
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: minQty,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).minimumQuantityL),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (double.tryParse(v ?? '') == null)
                        ? l10n.enterValidQuantity
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: maxQty,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).maximumQuantityOptional),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(AppLocalizations.of(context).availableShifts,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                  Wrap(
                    spacing: 8,
                    children: deliveryShiftOrder
                        .map(
                          (s) => FilterChip(
                            label: Text(deliveryShiftLabel(s)),
                            selected: selectedShifts.contains(s),
                            onSelected: (sel) => setState(() {
                              if (sel) {
                                selectedShifts.add(s);
                              } else {
                                selectedShifts.remove(s);
                              }
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppLocalizations.of(context).availableForNewCustomers),
                    value: isAvailable,
                    onChanged: (v) => setState(() => isAvailable = v),
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
                      if (selectedShifts.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                              content: Text(AppLocalizations.of(context).selectAtLeastOneShift)),
                        );
                        return;
                      }
                      setState(() => saving = true);
                      try {
                        await ref.read(farmApiProvider).createProduct(
                              farmId,
                              name: name.text.trim(),
                              milkType: milkType,
                              description: description.text.trim(),
                              currentRatePerLitre: rate.text.trim(),
                              minimumQuantity: minQty.text.trim(),
                              maximumQuantity: maxQty.text.trim(),
                              availableShifts: selectedShifts.toList(),
                              isAvailable: isAvailable,
                            );
                        ref.invalidate(farmProductsProvider);
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
              child: Text(saving ? l10n.saving : l10n.add),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeRateDialog(
    BuildContext context,
    WidgetRef ref,
    String farmId,
    FarmProductModel product,
  ) async {
    final l10n = AppLocalizations.of(context);
    final rate = TextEditingController(text: product.currentRatePerLitre);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).marketRateTitle(product.name)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).todaysRateAppliesHint,
              style: TextStyle(color: Dk.of(ctx).muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rate,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.ratePerLitre,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    final value = rate.text.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) => rate.dispose());
    if (ok != true) return;
    if (double.tryParse(value) == null || double.parse(value) <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.enterValidAmount)),
        );
      }
      return;
    }
    try {
      await ref.read(farmApiProvider).changeRate(
            farmId,
            product.id,
            ratePerLitre: value,
          );
      ref.invalidate(farmProductsProvider);
      await Future.wait([
        ref.read(farmProductsProvider.future),
        refreshFarmDashboard(ref),
      ]);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).rateUpdatedTo('$value'))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _onAction(
    WidgetRef ref,
    BuildContext context,
    String farmId,
    FarmProductModel product,
    String action,
  ) async {
    try {
      if (action == 'change_rate') {
        await _changeRateDialog(context, ref, farmId, product);
        return;
      }
      if (action == 'delete') {
        await ref.read(farmApiProvider).deleteProduct(farmId, product.id);
      } else {
        await ref
            .read(farmApiProvider)
            .setProductActive(farmId, product.id, action == 'activate');
      }
      ref.invalidate(farmProductsProvider);
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
    final productsAsync = ref.watch(farmProductsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: farmIdAsync.maybeWhen(
        data: (farmId) => FloatingActionButton(
          onPressed: () => _openAddDialog(context, ref, farmId),
          child: const Icon(Icons.add),
        ),
        orElse: () => null,
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return farmIdAsync.maybeWhen(
              data: (farmId) => DkEmpty(
                message:
                    'No products yet.\nAdd milk products and rates so customers can request delivery.',
                actionLabel: 'Add product',
                onAction: () => _openAddDialog(context, ref, farmId),
              ),
              orElse: () => DkEmpty(message: AppLocalizations.of(context).noProductsYet),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(farmProductsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, i) {
                final p = products[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    tileColor: Dk.of(context).milkWhite,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    leading: Icon(
                      Icons.water_drop,
                      color:
                          p.isAvailable ? AppColors.teal : Dk.of(context).muted,
                    ),
                    title: Text("${p.name} · ${p.milkType}"),
                    subtitle: Text(
                      AppLocalizations.of(context).rateMinQty(
                            '${p.currentRatePerLitre}',
                            formatLitresString(p.minimumQuantity),
                          ) +
                          (p.maximumQuantity != null
                              ? ' · max ${formatLitresString(p.maximumQuantity)}'
                              : '') +
                          '\n' +
                          AppLocalizations.of(context).shiftsColon(
                            productDeliveryShifts(p.availableShifts)
                                .map(deliveryShiftLabel)
                                .join(', '),
                          ),
                    ),
                    isThreeLine: true,
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        backgroundColor: Dk.of(context).milkWhite,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (ctx) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${p.name} · ${p.milkType}",
                                style: Theme.of(ctx)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(AppLocalizations.of(context).ratePerLitreValue('${p.currentRatePerLitre}')),
                              Text(
                                "${AppLocalizations.of(context).minColon(formatLitresString(p.minimumQuantity))}${p.maximumQuantity != null ? ' · Max: ${formatLitresString(p.maximumQuantity)}' : ''}",
                              ),
                              Text(
                                AppLocalizations.of(context).shiftsColon(productDeliveryShifts(p.availableShifts).map(deliveryShiftLabel).join(', ')),                              ),
                              Text(
                                  AppLocalizations.of(context).availableColon(p.isAvailable ? AppLocalizations.of(context).yes : AppLocalizations.of(context).no)),
                              if ((p.description ?? '').isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(p.description!),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    farmIdAsync.whenData(
                                      (farmId) => _changeRateDialog(
                                        context,
                                        ref,
                                        farmId,
                                        p,
                                      ),
                                    );
                                  },
                                  child: Text(AppLocalizations.of(context).changeTodaysRate),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: Text(l10n.close),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) => farmIdAsync.whenData(
                        (farmId) => _onAction(ref, context, farmId, p, action),
                      ),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'change_rate',
                          child: Text(AppLocalizations.of(context).changeTodaysRate),
                        ),
                        PopupMenuItem(
                          value: p.isAvailable ? 'deactivate' : 'activate',
                          child:
                              Text(p.isAvailable ? AppLocalizations.of(context).deactivate : AppLocalizations.of(context).activate),
                        ),
                        PopupMenuItem(
                            value: 'delete', child: Text(l10n.delete)),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DkEmpty(
          message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(farmProductsProvider),
        ),
      ),
    );
  }
}
