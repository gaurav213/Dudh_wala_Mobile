import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/launch_helpers.dart';
import '../../../../core/utils/location_helpers.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/customer_marketplace_models.dart';
import '../providers/customer_marketplace_providers.dart';

/// Controllers outlive the sheet's last frame if disposed in `finally` right
/// after `showModalBottomSheet` returns — dispose on the next frame instead.
void _disposeNextFrame(Iterable<TextEditingController> controllers) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    for (final c in controllers) {
      c.dispose();
    }
  });
}

/// Light leaf/warning alphas wash out on dark surfaces — bump contrast in dark.
({Color accent, Color bg, Color border}) _pinBannerColors(
  BuildContext context, {
  required bool saved,
}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  if (saved) {
    final accent = dark ? AppColors.teal : AppColors.leaf;
    return (
      accent: accent,
      bg: accent.withValues(alpha: dark ? 0.22 : 0.08),
      border: accent.withValues(alpha: dark ? 0.55 : 0.25),
    );
  }
  final accent = dark ? const Color(0xFFE2A85A) : AppColors.warning;
  return (
    accent: accent,
    bg: accent.withValues(alpha: dark ? 0.18 : 0.12),
    border: accent.withValues(alpha: dark ? 0.45 : 0.35),
  );
}

class CustomerAddressesScreen extends ConsumerWidget {
  const CustomerAddressesScreen({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    CustomerAddressModel? existing,
  }) async {
    final formKey = GlobalKey<FormState>();
    final label = TextEditingController(text: existing?.label ?? '');
    final line1 = TextEditingController(text: existing?.addressLine1 ?? '');
    final line2 = TextEditingController(text: existing?.addressLine2 ?? '');
    final area = TextEditingController(text: existing?.area ?? '');
    final city = TextEditingController(text: existing?.city ?? '');
    final state = TextEditingController(text: existing?.state ?? '');
    final postalCode = TextEditingController(text: existing?.postalCode ?? '');
    final instructions =
        TextEditingController(text: existing?.deliveryInstructions ?? '');
    var isDefault = existing?.isDefault ?? false;
    var latitude = existing?.latitude;
    var longitude = existing?.longitude;
    String? locationSource;
    String? locationAccuracyMeters;
    var saving = false;
    var pinning = false;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Dk.of(context).milkWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (dialogContext) {
          final viewInsets = MediaQuery.viewInsetsOf(dialogContext);
          final sheetHeight = MediaQuery.sizeOf(dialogContext).height * 0.92;

          return StatefulBuilder(
            builder: (dialogContext, setState) {
              final hasPin = latitude != null &&
                  longitude != null &&
                  latitude!.isNotEmpty &&
                  longitude!.isNotEmpty;

              InputDecoration fieldDecoration(String text, {String? hint}) {
                return InputDecoration(
                  labelText: text,
                  hintText: hint,
                  isDense: true,
                );
              }

              Widget sectionLabel(String text) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 4),
                  child: Text(
                    text,
                    style:
                        Theme.of(dialogContext).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Dk.of(context).ink,
                            ),
                  ),
                );
              }

              Future<void> save() async {
                if (!formKey.currentState!.validate()) return;
                setState(() => saving = true);
                try {
                  final api = ref.read(customerMarketplaceApiProvider);
                  if (existing == null) {
                    await api.createAddress(
                      label: label.text.trim(),
                      addressLine1: line1.text.trim(),
                      addressLine2: line2.text.trim(),
                      area: area.text.trim(),
                      city: city.text.trim(),
                      state: state.text.trim(),
                      postalCode: postalCode.text.trim(),
                      latitude: latitude,
                      longitude: longitude,
                      locationSource: locationSource,
                      locationAccuracyMeters: locationAccuracyMeters,
                      deliveryInstructions: instructions.text.trim(),
                      isDefault: isDefault,
                    );
                  } else {
                    await api.updateAddress(existing.id, {
                      'label': label.text.trim(),
                      'addressLine1': line1.text.trim(),
                      'addressLine2': line2.text.trim(),
                      'area': area.text.trim(),
                      'city': city.text.trim(),
                      'state': state.text.trim(),
                      'postalCode': postalCode.text.trim(),
                      'deliveryInstructions': instructions.text.trim(),
                      'isDefault': isDefault,
                      if (latitude != null) 'latitude': latitude,
                      if (locationSource != null)
                        'locationSource': locationSource,
                      if (locationAccuracyMeters != null)
                        'locationAccuracyMeters': locationAccuracyMeters,
                      if (longitude != null) 'longitude': longitude,
                    });
                  }
                  ref.invalidate(customerAddressesProvider);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                } catch (e) {
                  setState(() => saving = false);
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext)
                        .showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              }

              Future<void> pinCurrentLocation() async {
                setState(() => pinning = true);
                try {
                  final pos =
                      await LocationHelpers.currentPosition(throwOnError: true);
                  if (pos == null) return;
                  setState(() {
                    latitude = pos.latitude.toStringAsFixed(7);
                    longitude = pos.longitude.toStringAsFixed(7);
                    locationSource = 'CUSTOMER_GPS';
                    locationAccuracyMeters =
                        pos.accuracyMeters?.toStringAsFixed(2);
                  });
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext)
                        .showSnackBar(SnackBar(content: Text('$e')));
                  }
                } finally {
                  if (dialogContext.mounted) setState(() => pinning = false);
                }
              }

              Future<void> pickMapCoordinates() async {
                final latCtrl = TextEditingController(text: latitude ?? '');
                final lngCtrl = TextEditingController(text: longitude ?? '');
                final ok = await showModalBottomSheet<bool>(
                  context: dialogContext,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Dk.of(context).milkWhite,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) {
                    final inset = MediaQuery.viewInsetsOf(ctx).bottom;
                    return Padding(
                      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + inset),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Dk.of(context)
                                    .muted
                                    .withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context).pasteMapCoordinates,
                            style:
                                Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context).pasteMapsCoordsHint,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: Dk.of(context).muted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => LaunchHelpers.openMap(
                              dialogContext,
                              address: [
                                line1.text,
                                area.text,
                                city.text,
                                postalCode.text,
                              ].where((e) => e.trim().isNotEmpty).join(', '),
                              latitude: double.tryParse(latCtrl.text),
                              longitude: double.tryParse(lngCtrl.text),
                            ),
                            icon: const Icon(Icons.map_outlined),
                            label: Text(AppLocalizations.of(context).openMaps),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: latCtrl,
                            decoration: fieldDecoration('Latitude'),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: lngCtrl,
                            decoration: fieldDecoration('Longitude'),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: Text(AppLocalizations.of(context).cancel),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: Text(AppLocalizations.of(context).useCoordinates),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
                if (ok == true) {
                  final lat = double.tryParse(latCtrl.text.trim());
                  final lng = double.tryParse(lngCtrl.text.trim());
                  _disposeNextFrame([latCtrl, lngCtrl]);
                  if (lat == null || lng == null) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                            content:
                                Text(AppLocalizations.of(context).enterValidLatLng)),
                      );
                    }
                    return;
                  }
                  setState(() {
                    latitude = lat.toStringAsFixed(7);
                    longitude = lng.toStringAsFixed(7);
                    locationSource = 'CUSTOMER_MAP_PIN';
                    locationAccuracyMeters = null;
                  });
                } else {
                  _disposeNextFrame([latCtrl, lngCtrl]);
                }
              }

              return Padding(
                padding: EdgeInsets.only(bottom: viewInsets.bottom),
                child: SizedBox(
                  height: sheetHeight,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Dk.of(context).muted.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                existing == null
                                    ? 'Add address'
                                    : 'Edit address',
                                style: Theme.of(dialogContext)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Dk.of(context).ink,
                                    ),
                              ),
                            ),
                            IconButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.of(dialogContext).pop(),
                              icon: const Icon(Icons.close),
                              tooltip: AppLocalizations.of(context).close,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Form(
                          key: formKey,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                            children: [
                              sectionLabel('Details'),
                              TextFormField(
                                controller: label,
                                textCapitalization: TextCapitalization.words,
                                decoration: fieldDecoration(
                                  'Label',
                                  hint: 'Home, Office, Parents…',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: line1,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: fieldDecoration(
                                  'Address line 1',
                                  hint: 'Building, street, landmark',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: line2,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: fieldDecoration(
                                  'Address line 2',
                                  hint: 'Flat / floor (optional)',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: area,
                                textCapitalization: TextCapitalization.words,
                                decoration: fieldDecoration('Area / locality'),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: city,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: fieldDecoration('City'),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Required'
                                              : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: postalCode,
                                      decoration: fieldDecoration('PIN'),
                                      keyboardType: TextInputType.number,
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Required'
                                              : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: state,
                                textCapitalization: TextCapitalization.words,
                                decoration: fieldDecoration('State'),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: instructions,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: fieldDecoration(
                                  'Delivery notes',
                                  hint: 'Gate code, floor, preferred spot…',
                                ),
                                maxLines: 2,
                                minLines: 2,
                              ),
                              const SizedBox(height: 8),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: Text(AppLocalizations.of(context).setAsDefaultAddress),
                                subtitle: Text(
                                  AppLocalizations.of(context).usedWhenPlacingRequests,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Dk.of(context).muted,
                                  ),
                                ),
                                value: isDefault,
                                activeThumbColor: AppColors.leaf,
                                onChanged: (v) => setState(() => isDefault = v),
                              ),
                              const SizedBox(height: 8),
                              sectionLabel('Exact delivery point'),
                              Builder(
                                builder: (context) {
                                  final tone =
                                      _pinBannerColors(context, saved: hasPin);
                                  return DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: tone.bg,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: tone.border),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          14, 14, 14, 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                hasPin
                                                    ? Icons.check_circle
                                                    : Icons.place_outlined,
                                                color: tone.accent,
                                                size: 22,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: hasPin
                                                    ? Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            AppLocalizations.of(context).exactDeliveryPointSaved,
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  tone.accent,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 2),
                                                          Text(
                                                            "${double.parse(latitude!).toStringAsFixed(5)}, ${double.parse(longitude!).toStringAsFixed(5)}",
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              height: 1.3,
                                                              color:
                                                                  Dk.of(context)
                                                                      .muted,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : Text(
                                                        AppLocalizations.of(context).standAtGateMarkDrop,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          height: 1.35,
                                                          color: Dk.of(context)
                                                              .ink,
                                                        ),
                                                      ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          FilledButton.tonalIcon(
                                            onPressed: pinning
                                                ? null
                                                : pinCurrentLocation,
                                            icon: Icon(
                                              pinning
                                                  ? Icons.hourglass_top
                                                  : Icons.my_location,
                                            ),
                                            label: Text(
                                              pinning
                                                  ? 'Reading GPS…'
                                                  : hasPin
                                                      ? 'Update from current location'
                                                      : 'Use current location',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          OutlinedButton.icon(
                                            onPressed: pickMapCoordinates,
                                            icon:
                                                const Icon(Icons.map_outlined),
                                            label:
                                                Text(AppLocalizations.of(context).pasteFromMaps),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: saving
                                      ? null
                                      : () => Navigator.of(dialogContext).pop(),
                                  child: Text(AppLocalizations.of(context).cancel),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: FilledButton(
                                  onPressed: saving ? null : save,
                                  child:
                                      Text(saving ? AppLocalizations.of(context).saving : 'Save address'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      _disposeNextFrame([
        label,
        line1,
        line2,
        area,
        city,
        state,
        postalCode,
        instructions,
      ]);
    }
  }

  Future<void> _markExactPoint(
    WidgetRef ref,
    BuildContext context,
    CustomerAddressModel address,
  ) async {
    try {
      final pos = await LocationHelpers.currentPosition(throwOnError: true);
      if (pos == null) return;
      await ref.read(customerMarketplaceApiProvider).updateAddress(address.id, {
        'latitude': pos.latitude.toStringAsFixed(7),
        'longitude': pos.longitude.toStringAsFixed(7),
      });
      ref.invalidate(customerAddressesProvider);
      if (context.mounted) {
        final scheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).exactDeliveryPointSaved,
              style: TextStyle(color: scheme.onInverseSurface),
            ),
            backgroundColor: scheme.inverseSurface,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _delete(WidgetRef ref, BuildContext context, String id) async {
    try {
      await ref.read(customerMarketplaceApiProvider).deleteAddress(id);
      ref.invalidate(customerAddressesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _setDefault(
      WidgetRef ref, BuildContext context, String id) async {
    try {
      await ref.read(customerMarketplaceApiProvider).setDefaultAddress(id);
      ref.invalidate(customerAddressesProvider);
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
    final addressesAsync = ref.watch(customerAddressesProvider);

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(l10n.navAddresses)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.add),
      ),
      body: addressesAsync.when(
        data: (addresses) {
          if (addresses.isEmpty) {
            return DkEmpty(
              message:
                  'No saved addresses yet.\nAdd one, then mark the exact map point for delivery staff.',
              actionLabel: l10n.add,
              onAction: () => _openForm(context, ref),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(customerAddressesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: addresses.length,
              itemBuilder: (context, i) {
                final a = addresses[i];
                final hasPin = a.latitude != null &&
                    a.longitude != null &&
                    a.latitude!.isNotEmpty &&
                    a.longitude!.isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Dk.of(context).milkWhite,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 6, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                a.isDefault
                                    ? Icons.star
                                    : Icons.location_on_outlined,
                                color: a.isDefault
                                    ? AppColors.leaf
                                    : Dk.of(context).muted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  a.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (a.isDefault)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Chip(
                                    label: Text(l10n.defaultLabel),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    padding: EdgeInsets.zero,
                                    labelStyle: const TextStyle(fontSize: 11),
                                    backgroundColor:
                                        AppColors.leaf.withValues(alpha: 0.12),
                                    side: BorderSide.none,
                                  ),
                                ),
                              PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action == 'default')
                                    _setDefault(ref, context, a.id);
                                  if (action == 'delete')
                                    _delete(ref, context, a.id);
                                  if (action == 'edit')
                                    _openForm(context, ref, existing: a);
                                  if (action == 'pin')
                                    _markExactPoint(ref, context, a);
                                  if (action == 'maps' && hasPin) {
                                    LaunchHelpers.openMap(
                                      context,
                                      address:
                                          '${a.addressLine1}, ${a.shortLine}',
                                      latitude: double.tryParse(a.latitude!),
                                      longitude: double.tryParse(a.longitude!),
                                    );
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                      value: 'edit', child: Text(l10n.edit)),
                                  PopupMenuItem(
                                    value: 'pin',
                                    child: Text(
                                      hasPin
                                          ? AppLocalizations.of(context).updateExactPoint
                                          : AppLocalizations.of(context).markExactDeliveryPoint,
                                    ),
                                  ),
                                  if (hasPin)
                                    PopupMenuItem(
                                      value: 'maps',
                                      child: Text(AppLocalizations.of(context).previewInMaps),
                                    ),
                                  if (!a.isDefault)
                                    PopupMenuItem(
                                      value: 'default',
                                      child: Text(AppLocalizations.of(context).setAsDefault),
                                    ),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: Text(l10n.delete)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${a.addressLine1}, ${a.shortLine} ${a.postalCode}",
                            style: TextStyle(
                              color: Dk.of(context).muted,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Builder(
                            builder: (context) {
                              final tone =
                                  _pinBannerColors(context, saved: hasPin);
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  color: tone.bg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: tone.border),
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 10, 12, 10),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        hasPin
                                            ? Icons.check_circle
                                            : Icons.place_outlined,
                                        size: 18,
                                        color: tone.accent,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: hasPin
                                            ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    l10n.exactDeliveryPointSaved,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: tone.accent,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "${double.parse(a.latitude!).toStringAsFixed(5)}, ${double.parse(a.longitude!).toStringAsFixed(5)}",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      height: 1.3,
                                                      color:
                                                          Dk.of(context).muted,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Text(
                                                AppLocalizations.of(context).noMapPinYet,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  height: 1.35,
                                                  color: tone.accent,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _markExactPoint(ref, context, a),
                              icon: const Icon(Icons.my_location, size: 18),
                              label: Text(
                                hasPin
                                    ? AppLocalizations.of(context).updateExactPoint
                                    : AppLocalizations.of(context).markExactDeliveryPoint,
                              ),
                            ),
                          ),
                        ],
                      ),
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
          onAction: () => ref.invalidate(customerAddressesProvider),
        ),
      ),
    );
  }
}
