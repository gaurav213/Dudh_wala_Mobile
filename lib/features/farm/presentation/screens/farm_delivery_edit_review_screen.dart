import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/utils/launch_helpers.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/farm_providers.dart';

class FarmDeliveryEditReviewScreen extends ConsumerStatefulWidget {
  const FarmDeliveryEditReviewScreen({super.key, required this.deliveryId});

  final String deliveryId;

  @override
  ConsumerState<FarmDeliveryEditReviewScreen> createState() =>
      _FarmDeliveryEditReviewScreenState();
}

class _FarmDeliveryEditReviewScreenState
    extends ConsumerState<FarmDeliveryEditReviewScreen> {
  bool _busy = false;

  Future<void> _act(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try {
      await fn();
      ref.invalidate(farmEditReviewProvider(widget.deliveryId));
      ref.invalidate(farmEditedTodayProvider);
      ref.invalidate(farmTodayMetricsProvider);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${l10n.reviews} ${l10n.saved}")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(farmEditReviewProvider(widget.deliveryId));
    return Scaffold(
      appBar: AppBar(
        title: Text("${l10n.delivery} ${l10n.edit} ${l10n.reviews}"),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DkEmpty(
          message: '$e',
          actionLabel: l10n.retry,
          onAction: () =>
              ref.invalidate(farmEditReviewProvider(widget.deliveryId)),
        ),
        data: (detail) {
          final d = detail.delivery;
          final review = '${d['editReviewStatus'] ?? ''}';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                detail.customerName ?? l10n.customer,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (detail.customerPhone != null)
                Text(detail.customerPhone!,
                    style: TextStyle(color: Dk.of(context).muted)),
              const SizedBox(height: 16),
              _row(
                'Original quantity',
                formatLitresString(detail.previousQuantity),
              ),
              _row(
                'Updated quantity',
                formatLitresString(
                  detail.newQuantity ??
                      (d['finalDeliveredQuantity'] == null
                          ? null
                          : '${d['finalDeliveredQuantity']}'),
                ),
              ),
              _row('Original amount', '₹${detail.previousAmount ?? '—'}'),
              _row('Updated amount',
                  '₹${detail.newAmount ?? d['amount'] ?? '—'}'),
              _row('Edit reason',
                  detail.editReason?.replaceAll('_', ' ') ?? '—'),
              if (detail.editNote != null && detail.editNote!.isNotEmpty)
                _row('Note', detail.editNote!),
              _row('Delivery staff', detail.staffName ?? '—'),
              _row('Review status', review.replaceAll('_', ' ')),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (detail.customerPhone != null)
                    OutlinedButton.icon(
                      onPressed: () =>
                          LaunchHelpers.call(context, detail.customerPhone),
                      icon: Icon(Icons.call),
                      label: Text("${l10n.call} ${l10n.customer}"),
                    ),
                  if (detail.staffPhone != null)
                    OutlinedButton.icon(
                      onPressed: () =>
                          LaunchHelpers.call(context, detail.staffPhone),
                      icon: const Icon(Icons.call),
                      label: Text("${l10n.call} ${l10n.staff}"),
                    ),
                ],
              ),
              if (review == 'PENDING_REVIEW') ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _act(
                            () => ref
                                .read(farmApiProvider)
                                .confirmEditReview(widget.deliveryId),
                          ),
                  child: Text(l10n.confirm),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _act(
                            () => ref
                                .read(farmApiProvider)
                                .flagEditReview(widget.deliveryId),
                          ),
                  child: Text(AppLocalizations.of(context).flagForReview),
                ),
              ],
              const SizedBox(height: 24),
              Text(AppLocalizations.of(context).timeline, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...detail.events.map(
                (e) => ListTile(
                  dense: true,
                  title: Text('${e['eventType']}'.replaceAll('_', ' ')),
                  subtitle: Text('${e['notes'] ?? ''}'),
                  trailing: Text(
                    '${e['createdAt'] ?? ''}'.length >= 16
                        ? '${e['createdAt']}'.substring(11, 16)
                        : '',
                    style: TextStyle(fontSize: 12, color: Dk.of(context).muted),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
              child:
                  Text(label, style: TextStyle(color: Dk.of(context).muted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
