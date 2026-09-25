import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/utils/delivery_shift_helpers.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../core/widgets/dk_skeleton.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/customer_marketplace_models.dart';
import '../providers/customer_marketplace_providers.dart';

const _milkTypes = <String?>[null, 'COW', 'BUFFALO', 'MIXED', 'TONED', 'OTHER'];
const _shifts = <String?>[null, ...deliveryShiftOrder];

class CustomerFindFarmsScreen extends ConsumerStatefulWidget {
  const CustomerFindFarmsScreen({super.key});

  @override
  ConsumerState<CustomerFindFarmsScreen> createState() =>
      _CustomerFindFarmsScreenState();
}

class _CustomerFindFarmsScreenState
    extends ConsumerState<CustomerFindFarmsScreen> {
  String? _selectedAddressId;
  String? _milkType;
  String? _shift;
  bool _didAutoSearch = false;

  void _runSearch([String? addressId]) {
    final id = addressId ?? _selectedAddressId;
    if (id == null) return;
    ref.read(farmSearchControllerProvider.notifier).search(
          addressId: id,
          milkType: _milkType,
          deliveryShift: _shift,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final addressesAsync = ref.watch(customerAddressesProvider);
    final searchState = ref.watch(farmSearchControllerProvider);

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(l10n.findFarms)),
      body: addressesAsync.when(
        data: (addresses) {
          if (addresses.isEmpty) {
            return DkEmpty(
              message: l10n.addAddressFirstForFarms,
              actionLabel: l10n.addAddress,
              onAction: () => context.push(AppRoutes.customerAddresses),
            );
          }
          final resolvedAddressId = _selectedAddressId ??
              addresses
                  .firstWhere((a) => a.isDefault, orElse: () => addresses.first)
                  .id;
          final selectedAddress = addresses.firstWhere(
            (a) => a.id == resolvedAddressId,
            orElse: () => addresses.first,
          );
          if (!_didAutoSearch) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _selectedAddressId = resolvedAddressId;
                _didAutoSearch = true;
              });
              _runSearch(resolvedAddressId);
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: Dk.of(context).milkWhite,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final picked = await showModalBottomSheet<String>(
                            context: context,
                            backgroundColor: Dk.of(context).milkWhite,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (ctx) {
                              return SafeArea(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 12, 8, 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Center(
                                        child: Container(
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Dk.of(context)
                                                .muted
                                                .withValues(alpha: 0.35),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          16,
                                          12,
                                          8,
                                        ),
                                        child: Text(
                                          l10n.deliverTo,
                                          style: Theme.of(ctx)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: Dk.of(context).ink,
                                              ),
                                        ),
                                      ),
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight:
                                              MediaQuery.sizeOf(ctx).height *
                                                  0.5,
                                        ),
                                        child: ListView.separated(
                                          shrinkWrap: true,
                                          itemCount: addresses.length,
                                          separatorBuilder: (_, __) => Divider(
                                            height: 1,
                                            color: Dk.of(context)
                                                .muted
                                                .withValues(alpha: 0.2),
                                          ),
                                          itemBuilder: (_, i) {
                                            final a = addresses[i];
                                            final selected =
                                                a.id == resolvedAddressId;
                                            return ListTile(
                                              selected: selected,
                                              selectedTileColor: AppColors.teal
                                                  .withValues(alpha: 0.12),
                                              leading: Icon(
                                                selected
                                                    ? Icons.check_circle
                                                    : Icons
                                                        .location_on_outlined,
                                                color: selected
                                                    ? AppColors.teal
                                                    : Dk.of(context).muted,
                                              ),
                                              title: Text(
                                                a.label,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: Dk.of(context).ink,
                                                ),
                                              ),
                                              subtitle: Text(
                                                a.shortLine,
                                                style: TextStyle(
                                                  color: Dk.of(context).muted,
                                                ),
                                              ),
                                              trailing: a.isDefault
                                                  ? Chip(
                                                      label: Text(
                                                          l10n.defaultLabel),
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                      padding: EdgeInsets.zero,
                                                      labelStyle:
                                                          const TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                      side: BorderSide.none,
                                                      backgroundColor: AppColors
                                                          .teal
                                                          .withValues(
                                                              alpha: 0.12),
                                                    )
                                                  : null,
                                              onTap: () =>
                                                  Navigator.of(ctx).pop(a.id),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                          if (picked == null) return;
                          setState(() => _selectedAddressId = picked);
                          _runSearch(picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.deliverTo,
                            isDense: true,
                            suffixIcon: Icon(Icons.keyboard_arrow_down),
                          ),
                          child: Text(
                            "${selectedAddress.label} — ${selectedAddress.shortLine}",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.3,
                              color: Dk.of(context).ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.milkType,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Dk.of(context).muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _milkTypes.map((t) {
                          final selected = _milkType == t;
                          return ChoiceChip(
                            label: Text(_milkTypeLabel(context, t)),
                            selected: selected,
                            onSelected: (_) => setState(() => _milkType = t),
                            selectedColor:
                                AppColors.teal.withValues(alpha: 0.22),
                            labelStyle: TextStyle(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Dk.of(context).ink,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? AppColors.teal
                                  : Dk.of(context).muted.withValues(alpha: 0.3),
                            ),
                            backgroundColor: Dk.of(context).cream,
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.shift,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Dk.of(context).muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<String?>(
                        segments: _shifts
                            .map(
                              (s) => ButtonSegment<String?>(
                                value: s,
                                label: Text(_shiftLabel(context, s)),
                              ),
                            )
                            .toList(),
                        selected: {_shift},
                        showSelectedIcon: false,
                        emptySelectionAllowed: false,
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          foregroundColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return Dk.of(context).ink;
                          }),
                          backgroundColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Theme.of(context).colorScheme.primary;
                            }
                            return Dk.of(context).cream;
                          }),
                        ),
                        onSelectionChanged: (values) {
                          if (values.isEmpty) return;
                          setState(() => _shift = values.first);
                        },
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => _runSearch(resolvedAddressId),
                        icon: const Icon(Icons.search),
                        label: Text(l10n.search),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _buildResults(searchState, resolvedAddressId)),
            ],
          );
        },
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            DkSkeleton.box(height: 56, borderRadius: 12),
            const SizedBox(height: 12),
            DkSkeleton.box(height: 14, width: 72, borderRadius: 6),
            const SizedBox(height: 8),
            DkSkeleton.box(height: 36, borderRadius: 18),
            const SizedBox(height: 12),
            DkSkeleton.box(height: 40, borderRadius: 12),
            const SizedBox(height: 12),
            DkSkeleton.box(height: 48, borderRadius: 12),
          ],
        ),
        error: (e, _) => DkEmpty(
          message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(customerAddressesProvider),
        ),
      ),
    );
  }

  Widget _buildResults(FarmSearchState state, String addressId) {
    final l10n = AppLocalizations.of(context);
    if (state.isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DkSkeleton.box(height: 88, borderRadius: 14),
          ),
        ),
      );
    }
    if (state.error != null) {
      return DkEmpty(
        message: '${AppLocalizations.of(context).couldNotLoad}.\n${state.error}',
        actionLabel: l10n.retry,
        onAction: () => _runSearch(addressId),
      );
    }
    if (!state.hasSearched) {
      return DkEmpty(
        message: AppLocalizations.of(context).searchFarmsNearYou,
        actionLabel: AppLocalizations.of(context).searchNow,
        onAction: () => _runSearch(addressId),
      );
    }
    final result = state.result;
    final items = result?.items ?? const [];
    if (items.isEmpty) {
      final reasons = result?.diagnosticReasons ?? const [];
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.search_off, size: 48, color: Dk.of(context).muted),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).noFarmsFoundSearch,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (reasons.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                AppLocalizations.of(context).tryDifferentMilkOrShift,
                textAlign: TextAlign.center,
                style: TextStyle(color: Dk.of(context).muted),
              ),
            )
          else
            ...reasons.map(
              (r) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  r.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Dk.of(context).muted),
                ),
              ),
            ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _FarmResultCard(
        farm: items[i],
        onTap: () => context.push(
          AppRoutes.customerFarmDetail(items[i].id),
          extra: CustomerFarmDetailArgs(
            farm: items[i],
            addressId: _selectedAddressId,
          ),
        ),
      ),
    );
  }

  String _milkTypeLabel(BuildContext context, String? type) {
    return localizedMilkType(AppLocalizations.of(context), type);
  }

  String _shiftLabel(BuildContext context, String? shift) {
    final l10n = AppLocalizations.of(context);
    if (shift == null) return l10n.anyFilter;
    return deliveryShiftLabel(shift, l10n);
  }
}

class _FarmResultCard extends StatelessWidget {
  const _FarmResultCard({required this.farm, required this.onTap});

  final FarmSearchResultModel farm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dk = Dk.of(context);
    final l10n = AppLocalizations.of(context);
    final match = _matchLabel(l10n, farm.serviceAreaMatch);
    final connectionLabel = () {
      if (!farm.connection.connected) return l10n.notConnected;
      final types = farm.connection.products
          .map((p) => localizedMilkType(l10n, p.milkType))
          .where((t) => t.isNotEmpty)
          .toSet()
          .join(', ');
      return types.isEmpty
          ? l10n.connected
          : l10n.connectedWithTypes(types);
    }();

    return Material(
      color: dk.milkWhite,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.foam,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_outlined,
                    color: AppColors.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${farm.area}, ${farm.city}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: dk.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (match.isNotEmpty)
                          Chip(
                            label: Text(match),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            labelPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        Chip(
                          label: Text(connectionLabel),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          backgroundColor: farm.connection.connected
                              ? AppColors.teal.withValues(alpha: 0.12)
                              : null,
                          side: BorderSide.none,
                        ),
                        Text(
                          AppLocalizations.of(context).productsCount('${farm.products.length}'),
                          style: TextStyle(color: dk.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: dk.muted),
            ],
          ),
        ),
      ),
    );
  }

  String _matchLabel(AppLocalizations l10n, String tier) {
    switch (tier) {
      case 'EXACT_PIN':
        return l10n.servesYourPostalCode;
      case 'AREA_CITY':
        return l10n.servesYourArea;
      case 'CITY':
        return l10n.servesYourCity;
      default:
        return '';
    }
  }
}
