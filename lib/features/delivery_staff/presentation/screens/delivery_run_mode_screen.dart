import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/utils/launch_helpers.dart';
import '../../../../core/utils/location_helpers.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/delivery_staff_models.dart';
import '../providers/delivery_staff_providers.dart';

/// Sequential "run mode" for a delivery round: swipe through today's open
/// deliveries one at a time with big prev/next controls and one-tap
/// delivered/skip actions, so staff don't need to re-open the full list
/// between stops.
class DeliveryRunModeScreen extends ConsumerStatefulWidget {
  const DeliveryRunModeScreen({super.key});

  @override
  ConsumerState<DeliveryRunModeScreen> createState() =>
      _DeliveryRunModeScreenState();
}

class _DeliveryRunModeScreenState extends ConsumerState<DeliveryRunModeScreen> {
  int _index = 0;
  bool _busy = false;
  StaffPosition? _staffPos;

  @override
  void initState() {
    super.initState();
    LocationHelpers.currentPosition().then((pos) {
      if (mounted && pos != null) setState(() => _staffPos = pos);
    });
  }

  List<DeliveryModel> _openDeliveries(List<DeliveryModel> all) {
    final open = all.where((d) => d.isOpen).toList();
    open.sort((a, b) {
      final distA = _distanceOrInfinity(a);
      final distB = _distanceOrInfinity(b);
      final byDistance = distA.compareTo(distB);
      if (byDistance != 0) return byDistance;
      final seqA = a.deliverySequence ?? 1 << 30;
      final seqB = b.deliverySequence ?? 1 << 30;
      return seqA.compareTo(seqB);
    });
    return open;
  }

  double _distanceOrInfinity(DeliveryModel d) {
    final pos = _staffPos;
    final lat = d.latitudeValue;
    final lng = d.longitudeValue;
    if (pos == null || lat == null || lng == null) return double.infinity;
    return LocationHelpers.distanceKm(
      fromLat: pos.latitude,
      fromLng: pos.longitude,
      toLat: lat,
      toLng: lng,
    );
  }

  Future<void> _act(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      FocusManager.instance.primaryFocus?.unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      await refreshDeliveryStaffData(ref);
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      setState(() {
        if (_index > 0) _index = _index.clamp(0, 9999);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) {
        await Future<void>.delayed(Duration.zero);
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveriesAsync = ref.watch(todayDeliveriesProvider);

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(AppLocalizations.of(context).runMode)),
      body: deliveriesAsync.when(
        data: (all) {
          final open = _openDeliveries(all);
          if (open.isEmpty) {
            return DkEmpty(message: AppLocalizations.of(context).done);
          }
          final i = _index.clamp(0, open.length - 1);
          final d = open[i];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "${AppLocalizations.of(context).delivery} ${i + 1} / ${open.length}",
                  style: TextStyle(
                      color: Dk.of(context).muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Dk.of(context).milkWhite,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.customerName ??
                              AppLocalizations.of(context).customer,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if ((d.address ?? '').isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(d.address!,
                              style: TextStyle(color: Dk.of(context).muted)),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          d.hasExactPin
                              ? AppLocalizations.of(context).map
                              : AppLocalizations.of(context).noData,
                          style: TextStyle(
                            color: d.hasExactPin
                                ? Dk.of(context).muted
                                : AppColors.warning,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "${formatLitres(num.tryParse(d.expectedQuantity) ?? 0)} · ${d.deliveryShift}",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          formatRupees(num.tryParse(d.amount) ?? 0),
                          style: const TextStyle(color: AppColors.leafDark),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    LaunchHelpers.call(context, d.mobileNumber),
                                icon: const Icon(Icons.call_outlined),
                                label: Text(AppLocalizations.of(context).call),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => LaunchHelpers.openMap(
                                  context,
                                  address: d.address,
                                  latitude: d.latitudeValue,
                                  longitude: d.longitudeValue,
                                ),
                                icon: const Icon(Icons.map_outlined),
                                label: Text(AppLocalizations.of(context).map),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _act(
                                          () => ref
                                              .read(deliveryStaffApiProvider)
                                              .markDelivered(d.id),
                                        ),
                                icon: const Icon(Icons.check_circle_outline),
                                label: Text(
                                    AppLocalizations.of(context).delivered),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _act(
                                          () => ref
                                              .read(deliveryStaffApiProvider)
                                              .skip(d.id,
                                                  notes: AppLocalizations.of(
                                                          context)
                                                      .skipped),
                                        ),
                                icon: const Icon(Icons.remove_circle_outline),
                                label: Text(AppLocalizations.of(context).skip),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            i > 0 ? () => setState(() => _index = i - 1) : null,
                        icon: const Icon(Icons.chevron_left),
                        label: Text(AppLocalizations.of(context).back),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: i < open.length - 1
                            ? () => setState(() => _index = i + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        label: Text(AppLocalizations.of(context).next),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DkEmpty(
          message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
          actionLabel: AppLocalizations.of(context).retry,
          onAction: () => ref.invalidate(todayDeliveriesProvider),
        ),
      ),
    );
  }
}
