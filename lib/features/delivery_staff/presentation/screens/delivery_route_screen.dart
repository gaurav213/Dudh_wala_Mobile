import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/utils/launch_helpers.dart';
import '../../../../core/utils/location_helpers.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/delivery_staff_models.dart';
import '../providers/delivery_staff_providers.dart';

/// Today's Route — nearest-first ordering using staff GPS + address pins.
class DeliveryRouteScreen extends ConsumerStatefulWidget {
  const DeliveryRouteScreen({super.key});

  @override
  ConsumerState<DeliveryRouteScreen> createState() =>
      _DeliveryRouteScreenState();
}

class _DeliveryRouteScreenState extends ConsumerState<DeliveryRouteScreen> {
  DeliveryRouteToday? _route;
  StaffPosition? _staffPos;
  LocationFailure? _locationFailure;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  bool _approximate = false;

  @override
  void initState() {
    super.initState();
    _bootstrap(requestPermission: true);
  }

  Future<void> _bootstrap({required bool requestPermission}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final loc = await LocationHelpers.requestPosition(
      forceRefresh: true,
      requestPermissionIfNeeded: requestPermission,
    );
    if (!mounted) return;
    if (loc.isOk) {
      _staffPos = loc.position;
      _locationFailure = null;
      _approximate =
          loc.position?.fromCache == true || loc.position?.isStale == true;
    } else {
      _staffPos = null;
      _locationFailure = loc.failure;
      _approximate = false;
    }
    await _loadRoute();
  }

  Future<void> _loadRoute() async {
    try {
      final route = await ref.read(deliveryStaffApiProvider).routeToday(
            latitude: _staffPos?.latitude,
            longitude: _staffPos?.longitude,
            includeCompleted: true,
          );
      if (!mounted) return;
      setState(() {
        _route = route;
        _loading = false;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
        _busy = false;
      });
    }
  }

  Future<void> _recalculate({bool refreshLocation = true}) async {
    setState(() => _busy = true);
    if (refreshLocation) {
      final loc = await LocationHelpers.requestPosition(forceRefresh: true);
      if (loc.isOk) {
        _staffPos = loc.position;
        _locationFailure = null;
        _approximate = loc.position?.fromCache == true;
      } else {
        _locationFailure = loc.failure;
      }
    }
    await _loadRoute();
  }

  Future<void> _afterStopAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await refreshDeliveryStaffData(ref);
      await _recalculate(refreshLocation: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _setStopLocation(DeliveryRouteStop stop) async {
    final loc = await LocationHelpers.requestPosition(forceRefresh: true);
    if (!loc.isOk || loc.position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).pleaseTryAgain)),
        );
      }
      return;
    }
    if (stop.addressId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).noData)),
        );
      }
      return;
    }
    await _afterStopAction(() async {
      await ref.read(deliveryStaffApiProvider).updateAddressLocation(
            addressId: stop.addressId!,
            latitude: loc.position!.latitude,
            longitude: loc.position!.longitude,
            locationSource: 'DELIVERY_STAFF_MAP_PIN',
            accuracyMeters: loc.position!.accuracyMeters,
            markVerified: true,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).route),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).refresh,
            onPressed: _busy ? null : () => _recalculate(refreshLocation: true),
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    DkEmpty(
                      message:
                          '${AppLocalizations.of(context).couldNotLoad}.\n$_error',
                      actionLabel: AppLocalizations.of(context).retry,
                      onAction: () => _bootstrap(requestPermission: true),
                    ),
                  ],
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final route = _route;
    if (route == null) {
      return DkEmpty(message: AppLocalizations.of(context).noData);
    }
    final next = route.nextStop ??
        route.stops.cast<DeliveryRouteStop?>().firstWhere(
              (s) => s!.isOpen,
              orElse: () => null,
            );

    return RefreshIndicator(
      onRefresh: () => _recalculate(refreshLocation: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LocationBanner(
            hasLocation: _staffPos != null,
            failure: _locationFailure,
            approximate: _approximate,
            orderingApplied: route.locationOrderingApplied,
            onRetry: () => _bootstrap(requestPermission: true),
            onOpenSettings: () async {
              if (_locationFailure ==
                  LocationFailure.permissionPermanentlyDenied) {
                await LocationHelpers.openAppSettings();
              } else {
                await LocationHelpers.openLocationSettings();
              }
            },
            onContinue: () => _bootstrap(requestPermission: false),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: AppLocalizations.of(context).pending,
                  value: '${route.pendingCount}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: AppLocalizations.of(context).done,
                  value: '${route.completedCount}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: AppLocalizations.of(context).remaining,
                  value:
                      formatLitres(num.tryParse(route.totalMilkRemaining) ?? 0),
                ),
              ),
            ],
          ),
          if (route.estimatedStraightLineLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              "${AppLocalizations.of(context).route}: ${route.estimatedStraightLineLabel}",
              style: TextStyle(color: Dk.of(context).muted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => context.push(AppRoutes.deliveryRunMode),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(AppLocalizations.of(context).route),
              ),
              OutlinedButton.icon(
                onPressed:
                    _busy ? null : () => _recalculate(refreshLocation: true),
                icon: const Icon(Icons.route),
                label: Text(AppLocalizations.of(context).refresh),
              ),
              OutlinedButton.icon(
                onPressed: next == null || !next.locationAvailable
                    ? null
                    : () => LaunchHelpers.navigate(
                          context,
                          latitude: next.latitudeValue!,
                          longitude: next.longitudeValue!,
                          label: next.customerName,
                        ),
                icon: const Icon(Icons.map_outlined),
                label: Text(AppLocalizations.of(context).map),
              ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context).next,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _NextCard(
              stop: next,
              busy: _busy,
              onNavigate: next.locationAvailable
                  ? () => LaunchHelpers.navigate(
                        context,
                        latitude: next.latitudeValue!,
                        longitude: next.longitudeValue!,
                        label: next.customerName,
                      )
                  : null,
              onCall: () => LaunchHelpers.call(context, next.mobileNumber),
              onOpen: () => context
                  .push(AppRoutes.deliveryDeliveryDetail(next.deliveryId)),
              onDeliver: () => _afterStopAction(
                () => ref
                    .read(deliveryStaffApiProvider)
                    .markDelivered(next.deliveryId),
              ),
              onSkip: () => _afterStopAction(
                () => ref.read(deliveryStaffApiProvider).skip(next.deliveryId),
              ),
              onSetLocation: () => _setStopLocation(next),
            ),
          ],
          const SizedBox(height: 20),
          Text(AppLocalizations.of(context).deliveries,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (route.stops.isEmpty)
            DkEmpty(message: AppLocalizations.of(context).emptyDefault)
          else
            for (final stop in route.stops)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StopTile(
                  stop: stop,
                  busy: _busy,
                  onOpen: () => context
                      .push(AppRoutes.deliveryDeliveryDetail(stop.deliveryId)),
                  onCall: () => LaunchHelpers.call(context, stop.mobileNumber),
                  onMap: stop.locationAvailable
                      ? () => LaunchHelpers.navigate(
                            context,
                            latitude: stop.latitudeValue!,
                            longitude: stop.longitudeValue!,
                            label: stop.customerName,
                          )
                      : null,
                  onDeliver: stop.isOpen
                      ? () => _afterStopAction(
                            () => ref
                                .read(deliveryStaffApiProvider)
                                .markDelivered(stop.deliveryId),
                          )
                      : null,
                  onSkip: stop.isOpen
                      ? () => _afterStopAction(
                            () => ref
                                .read(deliveryStaffApiProvider)
                                .skip(stop.deliveryId),
                          )
                      : null,
                  onSetLocation: () => _setStopLocation(stop),
                  onConfirmLocation: stop.addressId != null &&
                          stop.locationAvailable &&
                          !stop.locationVerified
                      ? () => _afterStopAction(
                            () => ref
                                .read(deliveryStaffApiProvider)
                                .confirmAddressLocation(stop.addressId!),
                          )
                      : null,
                ),
              ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _LocationBanner extends StatelessWidget {
  const _LocationBanner({
    required this.hasLocation,
    required this.failure,
    required this.approximate,
    required this.orderingApplied,
    required this.onRetry,
    required this.onOpenSettings,
    required this.onContinue,
  });

  final bool hasLocation;
  final LocationFailure? failure;
  final bool approximate;
  final bool orderingApplied;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    if (hasLocation && orderingApplied) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Dk.of(context).foam,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          approximate
              ? AppLocalizations.of(context).route
              : AppLocalizations.of(context).route,
          style: const TextStyle(fontSize: 13),
        ),
      );
    }

    String message = AppLocalizations.of(context).map;
    if (failure == LocationFailure.serviceDisabled) {
      message = AppLocalizations.of(context).pleaseTryAgain;
    } else if (failure == LocationFailure.permissionPermanentlyDenied) {
      message = AppLocalizations.of(context).settings;
    } else if (failure == LocationFailure.permissionDenied) {
      message = AppLocalizations.of(context).map;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                  onPressed: onRetry,
                  child: Text(AppLocalizations.of(context).retry)),
              TextButton(
                  onPressed: onOpenSettings,
                  child: Text(AppLocalizations.of(context).settings)),
              TextButton(
                  onPressed: onContinue,
                  child: Text(AppLocalizations.of(context).continueAction)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Dk.of(context).milkWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: Dk.of(context).muted, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _NextCard extends StatelessWidget {
  const _NextCard({
    required this.stop,
    required this.busy,
    required this.onNavigate,
    required this.onCall,
    required this.onOpen,
    required this.onDeliver,
    required this.onSkip,
    required this.onSetLocation,
  });

  final DeliveryRouteStop stop;
  final bool busy;
  final VoidCallback? onNavigate;
  final VoidCallback onCall;
  final VoidCallback onOpen;
  final VoidCallback onDeliver;
  final VoidCallback onSkip;
  final VoidCallback onSetLocation;

  @override
  Widget build(BuildContext context) {
    final extra = num.tryParse(stop.customerExtraQuantity) ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.leaf,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stop.customerName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stop.locationAvailable
                ? (stop.distanceLabel ??
                    LocationHelpers.formatDistance(
                        stop.distanceMeters?.toDouble()))
                : AppLocalizations.of(context).noData,
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "${formatLitres(num.tryParse(stop.totalExpectedQuantity) ?? 0)}"
            '${extra > 0 ? ' · +${formatLitres(extra)} extra' : ''}'
            ' · ${stop.deliveryShift}',
            style: const TextStyle(color: Colors.white),
          ),
          if ((stop.address ?? '').isNotEmpty)
            Text(stop.address!,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onNavigate != null)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.leafDark,
                  ),
                  onPressed: busy ? null : onNavigate,
                  child: Text(AppLocalizations.of(context).map),
                )
              else
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.leafDark,
                  ),
                  onPressed: busy ? null : onSetLocation,
                  child: Text(AppLocalizations.of(context).map),
                ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                ),
                onPressed: busy ? null : onCall,
                child: Text(AppLocalizations.of(context).call),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                ),
                onPressed: busy ? null : onOpen,
                child: Text(AppLocalizations.of(context).delivery),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                ),
                onPressed: busy ? null : onDeliver,
                child: Text(AppLocalizations.of(context).deliver),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                ),
                onPressed: busy ? null : onSkip,
                child: Text(AppLocalizations.of(context).skip),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.stop,
    required this.busy,
    required this.onOpen,
    required this.onCall,
    required this.onMap,
    required this.onDeliver,
    required this.onSkip,
    required this.onSetLocation,
    required this.onConfirmLocation,
  });

  final DeliveryRouteStop stop;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onCall;
  final VoidCallback? onMap;
  final VoidCallback? onDeliver;
  final VoidCallback? onSkip;
  final VoidCallback onSetLocation;
  final VoidCallback? onConfirmLocation;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Dk.of(context).milkWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Dk.of(context).foam,
                    child: Text(
                      "${stop.sequence}",
                      style: TextStyle(
                        color: AppColors.leaf,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          stop.locationAvailable
                              ? (stop.distanceLabel ?? '—')
                              : AppLocalizations.of(context).noData,
                          style: TextStyle(
                            color: stop.locationAvailable
                                ? AppColors.leafDark
                                : AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    stop.status.replaceAll('_', ' '),
                    style: TextStyle(color: Dk.of(context).muted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "${formatLitres(num.tryParse(stop.totalExpectedQuantity) ?? 0)}"
                ' · ${stop.area ?? stop.address ?? '—'}',
                style: const TextStyle(fontSize: 13),
              ),
              if (stop.locationVerified)
                Text(
                  AppLocalizations.of(context).done,
                  style: TextStyle(color: AppColors.success, fontSize: 12),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: busy ? null : onCall,
                    child: Text(AppLocalizations.of(context).call),
                  ),
                  if (onMap != null)
                    OutlinedButton(
                      onPressed: busy ? null : onMap,
                      child: Text(AppLocalizations.of(context).map),
                    )
                  else ...[
                    OutlinedButton(
                      onPressed: busy ? null : onSetLocation,
                      child: Text(AppLocalizations.of(context).map),
                    ),
                    OutlinedButton(
                      onPressed: busy
                          ? null
                          : () => LaunchHelpers.copyText(context, stop.address),
                      child: Text(
                          "${AppLocalizations.of(context).copy} ${AppLocalizations.of(context).address}"),
                    ),
                  ],
                  OutlinedButton(
                    onPressed: busy ? null : onOpen,
                    child: Text(AppLocalizations.of(context).open),
                  ),
                  if (onDeliver != null)
                    FilledButton(
                      onPressed: busy ? null : onDeliver,
                      child: Text(AppLocalizations.of(context).deliver),
                    ),
                  if (onSkip != null)
                    OutlinedButton(
                      onPressed: busy ? null : onSkip,
                      child: Text(AppLocalizations.of(context).skip),
                    ),
                  if (onConfirmLocation != null)
                    TextButton(
                      onPressed: busy ? null : onConfirmLocation,
                      child: Text(
                          "${AppLocalizations.of(context).confirm} ${AppLocalizations.of(context).address}"),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
