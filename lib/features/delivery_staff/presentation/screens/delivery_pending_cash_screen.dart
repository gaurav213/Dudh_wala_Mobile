import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/delivery_staff_models.dart';
import '../providers/delivery_staff_providers.dart';

class DeliveryPendingCashScreen extends ConsumerWidget {
  const DeliveryPendingCashScreen({super.key});

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    PaymentModel payment,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).confirm),
        content: Text(
          "${AppLocalizations.of(context).confirm} ${formatRupees(num.tryParse(payment.amount) ?? 0)} · "
          '${payment.customerName ?? 'customer'}?',
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
    if (ok != true) return;
    try {
      await ref.read(deliveryStaffApiProvider).confirmCash(payment.id);
      ref.invalidate(deliveryPendingCashProvider);
      await refreshDeliveryStaffData(ref);
      try {
        await ref.read(deliveryPendingCashProvider.future);
      } catch (_) {}
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).success)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    PaymentModel payment,
  ) async {
    final notesController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).reject),
        content: TextField(
          controller: notesController,
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
            child: Text(AppLocalizations.of(context).reject),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final notes = notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim();
      await ref
          .read(deliveryStaffApiProvider)
          .rejectCash(payment.id, notes: notes);
      ref.invalidate(deliveryPendingCashProvider);
      await refreshDeliveryStaffData(ref);
      try {
        await ref.read(deliveryPendingCashProvider.future);
      } catch (_) {}
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).success)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      notesController.dispose();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pendingAsync = ref.watch(deliveryPendingCashProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(l10n.pendingCashTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(deliveryPendingCashProvider);
        },
        child: pendingAsync.when(
          data: (claims) {
            if (claims.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  DkEmpty(message: l10n.noPendingCash),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: claims.length,
              itemBuilder: (context, i) {
                final p = claims[i];
                final imageUrl = mediaUrl(p.proofImageUrl);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
                                p.customerName ??
                                    AppLocalizations.of(context).customer,
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              formatRupees(num.tryParse(p.amount) ?? 0),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        if (p.notes != null && p.notes!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            p.notes!,
                            style: TextStyle(
                                color: Dk.of(context).muted, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 10),
                        if (imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                alignment: Alignment.center,
                                color: Dk.of(context).foam,
                                child: Text(
                                  AppLocalizations.of(context).couldNotLoad,
                                  style: TextStyle(color: Dk.of(context).muted),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 80,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Dk.of(context).foam,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppLocalizations.of(context).noData,
                              style: TextStyle(color: Dk.of(context).muted),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _reject(context, ref, p),
                                child: Text(l10n.reject),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _confirm(context, ref, p),
                                child: Text(l10n.confirm),
                              ),
                            ),
                          ],
                        ),
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
                  message: '${AppLocalizations.of(context).couldNotLoad}.\n$e'),
            ],
          ),
        ),
      ),
    );
  }
}
