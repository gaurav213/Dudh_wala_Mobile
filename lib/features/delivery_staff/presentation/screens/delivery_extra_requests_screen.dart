import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/delivery_staff_models.dart';
import '../providers/delivery_staff_providers.dart';

class DeliveryExtraRequestsScreen extends ConsumerWidget {
  const DeliveryExtraRequestsScreen({super.key});

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    ExtraRequestModel request, {
    required bool accept,
  }) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(accept
            ? AppLocalizations.of(context).accept
            : AppLocalizations.of(context).reject),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
              labelText: AppLocalizations.of(context).notesOptional),
          maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppLocalizations.of(context).cancel)),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppLocalizations.of(context).confirm)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final api = ref.read(deliveryStaffApiProvider);
      final notes =
          controller.text.trim().isEmpty ? null : controller.text.trim();
      if (accept) {
        await api.acceptExtraRequest(request.id, notes: notes);
      } else {
        await api.rejectExtraRequest(request.id, notes: notes);
      }
      await refreshDeliveryStaffData(ref);
      try {
        await ref.read(assignedExtraRequestsProvider.future);
      } catch (_) {}
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(assignedExtraRequestsProvider);
    final dashboardAsync = ref.watch(deliveryStaffDashboardProvider);
    final canApprove = dashboardAsync
            .asData?.value.permissions?.deliveryStaffCanApproveExtraRequests ==
        true;

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar:
          AppBar(title: Text(AppLocalizations.of(context).navExtraRequests)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(assignedExtraRequestsProvider);
          ref.invalidate(deliveryStaffDashboardProvider);
        },
        child: requestsAsync.when(
          data: (requests) {
            if (requests.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: 80),
                  DkEmpty(message: AppLocalizations.of(context).emptyDefault),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length + (canApprove ? 0 : 1),
              itemBuilder: (context, i) {
                if (!canApprove && i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      AppLocalizations.of(context).details,
                      style: TextStyle(color: Dk.of(context).muted),
                    ),
                  );
                }
                final r = requests[canApprove ? i : i - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
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
                                "+${formatLitres(num.tryParse(r.requestedQuantity) ?? 0)} · ${r.deliveryDate}",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Chip(
                              label: Text(r.status,
                                  style: const TextStyle(fontSize: 11)),
                              backgroundColor: (r.isPending
                                      ? AppColors.warning
                                      : Dk.of(context).muted)
                                  .withValues(alpha: 0.12),
                              visualDensity: VisualDensity.compact,
                              side: BorderSide.none,
                            ),
                          ],
                        ),
                        if ((r.notes ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(r.notes!,
                              style: TextStyle(color: Dk.of(context).muted)),
                        ],
                        if (r.isPending && canApprove) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      _review(context, ref, r, accept: false),
                                  child:
                                      Text(AppLocalizations.of(context).reject),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () =>
                                      _review(context, ref, r, accept: true),
                                  child:
                                      Text(AppLocalizations.of(context).accept),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
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
                actionLabel: AppLocalizations.of(context).retry,
                onAction: () => ref.invalidate(assignedExtraRequestsProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
