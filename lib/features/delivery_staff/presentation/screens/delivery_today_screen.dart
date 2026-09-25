import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/location_helpers.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/delivery_staff_models.dart';
import '../providers/delivery_staff_providers.dart';
import '../widgets/delivery_tile.dart';

enum _TodayFilter { all, remaining, done, pending, out, delivered, skipped }

class DeliveryTodayScreen extends ConsumerStatefulWidget {
  const DeliveryTodayScreen({super.key, this.initialFilter});

  final String? initialFilter;

  @override
  ConsumerState<DeliveryTodayScreen> createState() =>
      _DeliveryTodayScreenState();
}

class _DeliveryTodayScreenState extends ConsumerState<DeliveryTodayScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  late _TodayFilter _filter;
  StaffPosition? _staffPos;

  @override
  void initState() {
    super.initState();
    _filter = _parseFilter(widget.initialFilter);
    _loadStaffPosition();
  }

  _TodayFilter _parseFilter(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'remaining':
      case 'pending':
        return _TodayFilter.pending;
      case 'out':
      case 'out_for_delivery':
        return _TodayFilter.out;
      case 'delivered':
      case 'done':
        return _TodayFilter.delivered;
      case 'skipped':
      case 'issues':
        return _TodayFilter.skipped;
      case 'remaining_open':
        return _TodayFilter.remaining;
      default:
        return _TodayFilter.all;
    }
  }

  Future<void> _loadStaffPosition() async {
    final pos = await LocationHelpers.currentPosition();
    if (!mounted || pos == null) return;
    setState(() => _staffPos = pos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DeliveryModel> _prepare(List<DeliveryModel> all) {
    final q = _search.trim().toLowerCase();
    final filtered = all.where((d) {
      switch (_filter) {
        case _TodayFilter.all:
          break;
        case _TodayFilter.remaining:
          if (!d.isOpen) return false;
        case _TodayFilter.done:
          if (d.isOpen) return false;
        case _TodayFilter.pending:
          if (!d.isPending) return false;
        case _TodayFilter.out:
          if (!d.isOutForDelivery) return false;
        case _TodayFilter.delivered:
          if (!d.isDelivered) return false;
        case _TodayFilter.skipped:
          if (d.status != 'SKIPPED' &&
              d.status != 'FAILED' &&
              d.status != 'DISPUTED' &&
              d.status != 'CANCELLED') {
            return false;
          }
      }
      if (q.isEmpty) return true;
      final name = (d.customerName ?? '').toLowerCase();
      final mobile = (d.mobileNumber ?? '').toLowerCase();
      final address = (d.address ?? '').toLowerCase();
      return name.contains(q) || mobile.contains(q) || address.contains(q);
    }).toList();

    filtered.sort((a, b) {
      final openRankA = a.isOpen ? 0 : 1;
      final openRankB = b.isOpen ? 0 : 1;
      if (openRankA != openRankB) return openRankA - openRankB;

      final distA = _distanceOrInfinity(a);
      final distB = _distanceOrInfinity(b);
      final byDistance = distA.compareTo(distB);
      if (byDistance != 0) return byDistance;

      final seqA = a.deliverySequence ?? 1 << 30;
      final seqB = b.deliverySequence ?? 1 << 30;
      return seqA.compareTo(seqB);
    });
    return filtered;
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

  void _clearSearch() {
    _searchController.clear();
    setState(() => _search = '');
  }

  @override
  Widget build(BuildContext context) {
    final deliveriesAsync = ref.watch(todayDeliveriesProvider);

    // Shell already provides the AppBar — only body + FAB here.
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.deliveryRunMode),
        backgroundColor: AppColors.leaf,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(AppLocalizations.of(context).runMode),
      ),
      body: RefreshIndicator(
        color: AppColors.leaf,
        onRefresh: () async {
          ref.invalidate(todayDeliveriesProvider);
          await _loadStaffPosition();
        },
        child: deliveriesAsync.when(
          data: (deliveries) {
            final visible = _prepare(deliveries);
            final remaining = deliveries.where((d) => d.isOpen).length;
            final done = deliveries.length - remaining;
            final pendingCount = deliveries.where((d) => d.isPending).length;
            final outCount = deliveries.where((d) => d.isOutForDelivery).length;
            final deliveredCount =
                deliveries.where((d) => d.isDelivered).length;
            final skippedCount = deliveries
                .where(
                  (d) =>
                      d.status == 'SKIPPED' ||
                      d.status == 'FAILED' ||
                      d.status == 'DISPUTED' ||
                      d.status == 'CANCELLED',
                )
                .length;
            final progress =
                deliveries.isEmpty ? 0.0 : done / deliveries.length;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onChanged: (value) => setState(() => _search = value),
                          style: TextStyle(color: Dk.of(context).ink),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context).search,
                            hintStyle: TextStyle(
                              color:
                                  Dk.of(context).muted.withValues(alpha: 0.8),
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: Dk.of(context).muted,
                            ),
                            suffixIcon: _search.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: AppLocalizations.of(context).clear,
                                    onPressed: _clearSearch,
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: Dk.of(context).muted,
                                    ),
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Dk.of(context)
                                    .muted
                                    .withValues(alpha: 0.28),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.leaf,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _FilterChip(
                                label:
                                    '${AppLocalizations.of(context).all} (${deliveries.length})',
                                selected: _filter == _TodayFilter.all,
                                onTap: () =>
                                    setState(() => _filter = _TodayFilter.all),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label:
                                    '${AppLocalizations.of(context).pending} ($pendingCount)',
                                selected: _filter == _TodayFilter.pending,
                                onTap: () => setState(
                                    () => _filter = _TodayFilter.pending),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label:
                                    '${AppLocalizations.of(context).out} ($outCount)',
                                selected: _filter == _TodayFilter.out,
                                onTap: () =>
                                    setState(() => _filter = _TodayFilter.out),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label:
                                    '${AppLocalizations.of(context).delivered} ($deliveredCount)',
                                selected: _filter == _TodayFilter.delivered,
                                onTap: () => setState(
                                    () => _filter = _TodayFilter.delivered),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label:
                                    '${AppLocalizations.of(context).skipped} ($skippedCount)',
                                selected: _filter == _TodayFilter.skipped,
                                onTap: () => setState(
                                    () => _filter = _TodayFilter.skipped),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label:
                                    '${AppLocalizations.of(context).remaining} ($remaining)',
                                selected: _filter == _TodayFilter.remaining,
                                onTap: () => setState(
                                    () => _filter = _TodayFilter.remaining),
                              ),
                            ],
                          ),
                        ),
                        if (_search.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            visible.isEmpty
                                ? AppLocalizations.of(context).noData
                                : '${visible.length} match${visible.length == 1 ? '' : 'es'} for “${_search.trim()}”',
                            style: TextStyle(
                              color: Dk.of(context).muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProgressCard(
                          done: done,
                          total: deliveries.length,
                          remaining: remaining,
                          progress: progress,
                          nearestEnabled: _staffPos != null,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                if (visible.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: DkEmpty(
                      message: _search.trim().isNotEmpty
                          ? AppLocalizations.of(context).noData
                          : deliveries.isEmpty
                              ? AppLocalizations.of(context).emptyDefault
                              : AppLocalizations.of(context).emptyDefault,
                      actionLabel: _search.trim().isNotEmpty
                          ? AppLocalizations.of(context).clear
                          : _filter != _TodayFilter.all
                              ? AppLocalizations.of(context).all
                              : null,
                      onAction: _search.trim().isNotEmpty
                          ? _clearSearch
                          : _filter != _TodayFilter.all
                              ? () => setState(() => _filter = _TodayFilter.all)
                              : null,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    sliver: SliverList.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final d = visible[index];
                        final distance = _distanceOrInfinity(d);
                        return DeliveryTile(
                          delivery: d,
                          stopNumber: index + 1,
                          distanceKm: distance.isFinite ? distance : null,
                        );
                      },
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 80),
              DkEmpty(
                message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
                actionLabel: AppLocalizations.of(context).retry,
                onAction: () => ref.invalidate(todayDeliveriesProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.done,
    required this.total,
    required this.remaining,
    required this.progress,
    required this.nearestEnabled,
  });

  final int done;
  final int total;
  final int remaining;
  final double progress;
  final bool nearestEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Dk.of(context).milkWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.leaf.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  total == 0
                      ? AppLocalizations.of(context).emptyDefault
                      : '$done / $total',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Dk.of(context).ink,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Dk.of(context).foam,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  AppLocalizations.of(context).remainingLeft('\$remaining'),
                  style: TextStyle(
                    color: AppColors.leafDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            nearestEnabled
                ? AppLocalizations.of(context).remaining
                : AppLocalizations.of(context).remaining,
            style: TextStyle(color: Dk.of(context).muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Dk.of(context).foam,
              color: AppColors.teal,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.leaf
                  : Dk.of(context).muted.withValues(alpha: 0.28),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.leafDark : Dk.of(context).ink,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
