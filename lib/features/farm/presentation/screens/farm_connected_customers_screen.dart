import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/feature_flags.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/farm_models.dart';
import '../providers/farm_providers.dart';
import 'farm_today_deliveries_screen.dart';

class FarmConnectedCustomersScreen extends ConsumerStatefulWidget {
  const FarmConnectedCustomersScreen({super.key});

  @override
  ConsumerState<FarmConnectedCustomersScreen> createState() =>
      _FarmConnectedCustomersScreenState();
}

class _FarmConnectedCustomersScreenState
    extends ConsumerState<FarmConnectedCustomersScreen> {
  Future<void> _assign(
    String subscriptionId,
    String? staffUserId,
  ) async {
    try {
      await ref.read(farmApiProvider).assignDeliveryPerson(
            subscriptionId,
            assignedDeliveryUserId: staffUserId,
          );
      ref.invalidate(farmConnectedCustomersProvider);
      await ref.read(farmConnectedCustomersProvider.future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).deliveryPersonUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _showAssignSheet(
    ConnectedCustomerModel customer,
    List<FarmMemberModel> staff,
  ) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Dk.of(context).milkWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.name ?? customer.mobileNumber ?? l10n.customer,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    color: Dk.of(context).ink,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context).mobileLabel(customer.mobileNumber ?? '—')),
            const SizedBox(height: 12),
            if (customer.subscriptions.isEmpty)
              Text(AppLocalizations.of(context).noActiveSubscriptionYet)
            else
              ...customer.subscriptions.map((sub) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${sub.milkType} · ${formatLitresString(sub.defaultQuantity)} · ${sub.deliveryShift}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String?>(
                        value: sub.assignedDeliveryUserId,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).deliveryPerson,
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(AppLocalizations.of(context).farmOwnerUnassigned),
                          ),
                          ...staff.map(
                            (m) => DropdownMenuItem<String?>(
                              value: m.userId,
                              child: Text(m.userName ?? m.userId),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          Navigator.of(ctx).pop();
                          _assign(sub.id, value);
                        },
                      ),
                    ],
                  ),
                );
              }),
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
  }

  Future<void> _openAddManagedDialog() async {
    final l10n = AppLocalizations.of(context);
    final farmId = await ref.read(currentFarmIdProvider.future);
    if (!mounted) return;

    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final mobile = TextEditingController();
    final address = TextEditingController();
    final quantity = TextEditingController(text: '1');
    final rate = TextEditingController(text: '60');
    final startDate = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );
    var milkType = 'COW';
    var shift = 'MORNING';
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) {
          return AlertDialog(
            title: Text("${l10n.add} ${l10n.customer}"),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context).noAppAccountNeeded,
                      style: TextStyle(
                        color: Dk.of(context).muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: name,
                      decoration: InputDecoration(labelText: l10n.name),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name required'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: mobile,
                      decoration: InputDecoration(
                        labelText: l10n.mobileNumber,
                        prefixText: '+91 ',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: address,
                      decoration: InputDecoration(
                        labelText: l10n.address,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: milkType,
                      decoration: InputDecoration(labelText: l10n.milkType),
                      items: [
                        DropdownMenuItem(value: 'COW', child: Text(AppLocalizations.of(context).cow)),
                        DropdownMenuItem(
                            value: 'BUFFALO', child: Text(AppLocalizations.of(context).buffalo)),
                      ],
                      onChanged: (v) =>
                          setLocal(() => milkType = v ?? milkType),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: quantity,
                      decoration: InputDecoration(labelText: l10n.quantityL),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (v == null ||
                              double.tryParse(v.trim()) == null ||
                              double.parse(v.trim()) <= 0)
                          ? 'Enter litres'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: rate,
                      decoration: InputDecoration(labelText: l10n.ratePerLitre),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (v == null ||
                              double.tryParse(v.trim()) == null ||
                              double.parse(v.trim()) <= 0)
                          ? 'Enter rate'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: shift,
                      decoration: InputDecoration(labelText: l10n.shift),
                      items: [
                        DropdownMenuItem(
                            value: 'MORNING', child: Text(l10n.morning)),
                        DropdownMenuItem(
                            value: 'EVENING', child: Text(l10n.evening)),
                      ],
                      onChanged: (v) => setLocal(() => shift = v ?? shift),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: startDate,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).startDateYmd,
                      ),
                      validator: (v) => (v == null ||
                              !RegExp(r'^\d{4}-\d{2}-\d{2}$')
                                  .hasMatch(v.trim()))
                          ? 'Use YYYY-MM-DD'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setLocal(() => saving = true);
                        try {
                          await ref.read(farmApiProvider).createManagedCustomer(
                                farmId,
                                name: name.text.trim(),
                                mobileNumber: mobile.text.trim().isEmpty
                                    ? null
                                    : mobile.text.trim(),
                                address: address.text.trim().isEmpty
                                    ? null
                                    : address.text.trim(),
                                milkType: milkType,
                                quantity: quantity.text.trim(),
                                ratePerLitre: rate.text.trim(),
                                deliveryShift: shift,
                                startDate: startDate.text.trim(),
                              );
                          ref.invalidate(farmConnectedCustomersProvider);
                          ref.invalidate(farmTodayDeliveriesProvider);
                          await ref.read(farmConnectedCustomersProvider.future);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context).customerAddedGenerateHint,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          setLocal(() => saving = false);
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('$e')),
                            );
                          }
                        }
                      },
                child: Text(saving ? l10n.saving : l10n.add),
              ),
            ],
          );
        },
      ),
    );

    name.dispose();
    mobile.dispose();
    address.dispose();
    quantity.dispose();
    rate.dispose();
    startDate.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final customersAsync = ref.watch(farmConnectedCustomersProvider);
    final staffAsync = ref.watch(farmStaffMembersProvider);

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddManagedDialog,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text("${l10n.add} ${l10n.customer}"),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(farmConnectedCustomersProvider);
          if (kDeliveryStaffEnabled) {
            ref.invalidate(farmStaffMembersProvider);
          }
          await ref.read(farmConnectedCustomersProvider.future);
        },
        child: customersAsync.when(
          data: (customers) {
            if (customers.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  DkEmpty(
                    message:
                        'No customers yet.\nAdd someone without an app, invite by phone, or accept requests.',
                    actionLabel: '${l10n.add} ${l10n.customer}',
                    onAction: _openAddManagedDialog,
                  ),
                ],
              );
            }
            final staff = !kDeliveryStaffEnabled
                ? <FarmMemberModel>[]
                : staffAsync.maybeWhen(
                    data: (members) => members
                        .where((m) => m.memberRole == 'DELIVERY_STAFF')
                        .toList(),
                    orElse: () => <FarmMemberModel>[],
                  );
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: customers.length,
              itemBuilder: (context, i) {
                final c = customers[i];
                final active = c.status == 'ACTIVE';
                String assignee;
                if (!kDeliveryStaffEnabled) {
                  assignee = 'You deliver yourself';
                } else if (c.subscriptions.isEmpty) {
                  assignee = 'No subscription';
                } else {
                  assignee = c.subscriptions.first.assignedDeliveryUserName ??
                      (c.subscriptions.first.assignedDeliveryUserId == null
                          ? 'Unassigned (you deliver)'
                          : 'Assigned');
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    tileColor: Dk.of(context).milkWhite,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    leading: CircleAvatar(
                      backgroundColor:
                          active ? Dk.of(context).foam : Dk.of(context).cream,
                      child: Icon(
                        Icons.person_outline,
                        color: active ? AppColors.leaf : Dk.of(context).muted,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.name ?? c.mobileNumber ?? l10n.customer,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (c.isManaged) ...[
                          const SizedBox(width: 6),
                          Chip(
                            label: Text(l10n.managed),
                            visualDensity: VisualDensity.compact,
                            labelStyle: const TextStyle(fontSize: 11),
                            backgroundColor: Dk.of(context).foam,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text("${c.mobileNumber ?? '—'} · $assignee"),
                    trailing: kDeliveryStaffEnabled
                        ? Icon(Icons.badge_outlined,
                            color: Dk.of(context).muted)
                        : null,
                    onTap: kDeliveryStaffEnabled
                        ? () => _showAssignSheet(c, staff)
                        : null,
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 80),
              DkEmpty(
                message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(farmConnectedCustomersProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
