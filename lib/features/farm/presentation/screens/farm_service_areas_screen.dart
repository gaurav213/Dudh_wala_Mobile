import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/farm_models.dart';
import '../providers/farm_providers.dart';

class FarmServiceAreasScreen extends ConsumerWidget {
  const FarmServiceAreasScreen({super.key});

  Future<void> _openAddDialog(
      BuildContext context, WidgetRef ref, String farmId) async {
    final l10n = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final areaName = TextEditingController();
    final city = TextEditingController();
    final state = TextEditingController();
    final postalCode = TextEditingController();
    final radius = TextEditingController();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text("${l10n.add} ${l10n.serviceAreas}"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: areaName,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context).areaName),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: city,
                    decoration: InputDecoration(labelText: l10n.city),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.required : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: state,
                    decoration: InputDecoration(labelText: l10n.state),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.required : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: postalCode,
                    decoration: InputDecoration(labelText: l10n.postalCode),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: radius,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).serviceRadiusKmOptional),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                        await ref.read(farmApiProvider).createServiceArea(
                              farmId,
                              areaName: areaName.text.trim(),
                              city: city.text.trim(),
                              state: state.text.trim(),
                              postalCode: postalCode.text.trim(),
                              serviceRadiusKm: radius.text.trim(),
                            );
                        ref.invalidate(farmServiceAreasProvider);
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

  Future<void> _onAction(
    WidgetRef ref,
    BuildContext context,
    String farmId,
    FarmServiceAreaModel area,
    String action,
  ) async {
    try {
      if (action == 'delete') {
        await ref.read(farmApiProvider).deleteServiceArea(farmId, area.id);
      } else {
        await ref
            .read(farmApiProvider)
            .setServiceAreaActive(farmId, area.id, action == 'activate');
      }
      ref.invalidate(farmServiceAreasProvider);
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
    final areasAsync = ref.watch(farmServiceAreasProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: farmIdAsync.maybeWhen(
        data: (farmId) => FloatingActionButton(
          onPressed: () => _openAddDialog(context, ref, farmId),
          child: const Icon(Icons.add),
        ),
        orElse: () => null,
      ),
      body: areasAsync.when(
        data: (areas) {
          if (areas.isEmpty) {
            return farmIdAsync.maybeWhen(
              data: (farmId) => DkEmpty(
                message:
                    'No service areas yet.\nAdd the areas you deliver to so customers can find you.',
                actionLabel: 'Add area',
                onAction: () => _openAddDialog(context, ref, farmId),
              ),
              orElse: () => DkEmpty(message: AppLocalizations.of(context).noServiceAreasYet),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(farmServiceAreasProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: areas.length,
              itemBuilder: (context, i) {
                final area = areas[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    tileColor: Dk.of(context).milkWhite,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    leading: Icon(
                      Icons.map_outlined,
                      color:
                          area.isActive ? AppColors.teal : Dk.of(context).muted,
                    ),
                    title: Text(area.areaName),
                    subtitle: Text(
                      "${area.city}, ${area.state}"
                      '${area.postalCode != null ? ' · ${area.postalCode}' : ''}'
                      '${area.serviceRadiusKm != null ? ' · ${area.serviceRadiusKm} km' : ''}',
                    ),
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
                                area.areaName,
                                style: Theme.of(ctx)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text("${area.city}, ${area.state}"),
                              if (area.postalCode != null)
                                Text(AppLocalizations.of(context).pinLabel(area.postalCode ?? '')),
                              if (area.serviceRadiusKm != null)
                                Text(AppLocalizations.of(context).radiusKmLabel('${area.serviceRadiusKm}')),
                              Text(AppLocalizations.of(context).activeYesNo(area.isActive ? AppLocalizations.of(context).yes : AppLocalizations.of(context).no)),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
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
                        (farmId) =>
                            _onAction(ref, context, farmId, area, action),
                      ),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: area.isActive ? 'deactivate' : 'activate',
                          child:
                              Text(area.isActive ? AppLocalizations.of(context).deactivate : AppLocalizations.of(context).activate),
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
          onAction: () => ref.invalidate(farmServiceAreasProvider),
        ),
      ),
    );
  }
}
