import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/utils/launch_helpers.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/delivery_staff_models.dart';
import '../providers/delivery_staff_providers.dart';
import '../widgets/delivery_tile.dart';

class DeliveryCustomersScreen extends ConsumerStatefulWidget {
  const DeliveryCustomersScreen({super.key});

  @override
  ConsumerState<DeliveryCustomersScreen> createState() =>
      _DeliveryCustomersScreenState();
}

class _DeliveryCustomersScreenState
    extends ConsumerState<DeliveryCustomersScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StaffCustomerSummary> _filter(List<StaffCustomerSummary> customers) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return customers;
    return customers.where((c) {
      final name = c.name.toLowerCase();
      final mobile = (c.mobileNumber ?? '').toLowerCase();
      final address = (c.addressSummary ?? '').toLowerCase();
      return name.contains(q) || mobile.contains(q) || address.contains(q);
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _search = '');
  }

  Future<void> _addExtraDelivery(StaffCustomerSummary customer) async {
    final qtyController = TextEditingController(text: '0.5');
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).extra),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).quantityL,
              style: TextStyle(color: Dk.of(context).muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).quantityL),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).notesOptional),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppLocalizations.of(context).cancel)),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppLocalizations.of(context).add)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final qty = qtyController.text.trim();
    if (double.tryParse(qty) == null || double.parse(qty) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).enterValidQuantity)),
      );
      return;
    }
    try {
      final delivery =
          await ref.read(deliveryStaffApiProvider).createAdHocExtra(
                subscriptionId: customer.subscriptionId,
                extraQuantity: qty,
                reason: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              );
      await refreshDeliveryStaffData(ref);
      if (!mounted) return;
      context.push(AppRoutes.deliveryDeliveryDetail(delivery.id),
          extra: delivery);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(deliveryStaffCustomersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppColors.leaf,
        onRefresh: () async => ref.invalidate(deliveryStaffCustomersProvider),
        child: customersAsync.when(
          data: (customers) {
            final visible = _filter(customers);
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) => setState(() => _search = value),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).search,
                        prefixIcon: Icon(Icons.search_rounded),
                        suffixIcon: _search.isEmpty
                            ? null
                            : IconButton(
                                tooltip: AppLocalizations.of(context).clear,
                                onPressed: _clearSearch,
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Dk.of(context).muted.withValues(alpha: 0.28),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.leaf,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (customers.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: DkEmpty(
                        message: AppLocalizations.of(context).emptyDefault),
                  )
                else if (visible.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: DkEmpty(
                      message: AppLocalizations.of(context).noData,
                      actionLabel: AppLocalizations.of(context).clear,
                      onAction: _clearSearch,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _CustomerCard(
                        customer: visible[i],
                        onAddExtra: () => _addExtraDelivery(visible[i]),
                      ),
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
                onAction: () => ref.invalidate(deliveryStaffCustomersProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerCard extends ConsumerWidget {
  const _CustomerCard({required this.customer, required this.onAddExtra});

  final StaffCustomerSummary customer;
  final VoidCallback onAddExtra;

  Color _statusColor(BuildContext context) {
    switch (customer.todayStatus) {
      case 'DELIVERED':
        return AppColors.success;
      case 'OUT_FOR_DELIVERY':
        return AppColors.teal;
      case 'SKIPPED':
      case 'FAILED':
        return AppColors.danger;
      case 'NONE':
        return Dk.of(context).muted;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extra = num.tryParse(customer.extraQuantityRequested) ?? 0;
    final staffExtra = num.tryParse(customer.staffExtraQuantity) ?? 0;
    return Material(
      color: Dk.of(context).milkWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () =>
            context.push(AppRoutes.deliveryCustomerDetail(customer.customerId)),
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
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          color: AppColors.leaf, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        if ((customer.addressSummary ?? '').isNotEmpty)
                          Text(
                            customer.addressSummary!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Dk.of(context).muted, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      customer.todayStatus == 'NONE'
                          ? AppLocalizations.of(context).noData
                          : deliveryStatusLabel(context, customer.todayStatus),
                      style:
                          TextStyle(fontSize: 11, color: _statusColor(context)),
                    ),
                    backgroundColor:
                        _statusColor(context).withValues(alpha: 0.12),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "${customer.milkType} · ${customer.deliveryShift}",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              if (!customer.scheduledToday && customer.deliveryId == null)
                Text(
                  AppLocalizations.of(context).noData,
                  style: TextStyle(color: Dk.of(context).muted),
                )
              else ...[
                Text(
                  "${AppLocalizations.of(context).defaultLabel} ${formatLitres(num.tryParse(customer.regularQuantity) ?? 0)}"
                  '${extra > 0 ? ' · ${AppLocalizations.of(context).extra} ${formatLitres(extra)}' : ''}'
                  '${staffExtra > 0 ? ' · ${AppLocalizations.of(context).staff} +${formatLitres(staffExtra)}' : ''}'
                  ' · ${AppLocalizations.of(context).total} ${formatLitres(num.tryParse(customer.todayTotalQuantity) ?? 0)}',
                  style: TextStyle(color: Dk.of(context).ink, fontSize: 13),
                ),
              ],
              if (customer.canViewCustomerBalance &&
                  customer.balance != null) ...[
                const SizedBox(height: 4),
                Text(
                  "${AppLocalizations.of(context).outstanding} ${formatRupees(num.tryParse(customer.balance!) ?? 0)}",
                  style: const TextStyle(
                      color: AppColors.leafDark, fontWeight: FontWeight.w700),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        LaunchHelpers.call(context, customer.mobileNumber),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: Text(AppLocalizations.of(context).call),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => LaunchHelpers.openMap(
                      context,
                      address: customer.addressSummary,
                    ),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: Text(AppLocalizations.of(context).map),
                  ),
                  if (customer.hasOpenDelivery)
                    FilledButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.deliveryDeliveryDetail(customer.deliveryId!),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(AppLocalizations.of(context).deliver),
                    )
                  else if (!customer.scheduledToday &&
                      customer.deliveryId == null)
                    FilledButton.icon(
                      onPressed: onAddExtra,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(AppLocalizations.of(context).extra),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.deliveryCustomerDetail(customer.customerId),
                      ),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(AppLocalizations.of(context).open),
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
