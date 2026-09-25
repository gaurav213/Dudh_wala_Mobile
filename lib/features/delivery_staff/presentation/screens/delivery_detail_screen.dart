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

class DeliveryDetailScreen extends ConsumerStatefulWidget {
  const DeliveryDetailScreen(
      {super.key, required this.deliveryId, this.initial});

  final String deliveryId;
  final DeliveryModel? initial;

  @override
  ConsumerState<DeliveryDetailScreen> createState() =>
      _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends ConsumerState<DeliveryDetailScreen> {
  bool _busy = false;

  /// Latest mutation result so the UI updates immediately without waiting on
  /// a refetch (and without falling back to the stale route `initial`).
  DeliveryModel? _latest;

  /// Defer rebuilds that remove hovered buttons — otherwise macOS/desktop
  /// floods `mouse_tracker.dart` assertions when widgets vanish under the cursor.
  Future<void> _safeSetState(VoidCallback fn) async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _run(Future<DeliveryModel> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = await action();
      await _safeSetState(() => _latest = updated);
      await refreshDeliveryStaffData(ref, deliveryId: widget.deliveryId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      await _safeSetState(() => _busy = false);
    }
  }

  Future<void> _outForDelivery() => _run(
        () => ref
            .read(deliveryStaffApiProvider)
            .outForDelivery(widget.deliveryId),
      );

  Future<void> _markDelivered() async {
    final result = await _promptQuantityAndNotes(
      title: AppLocalizations.of(context).markDelivered,
      quantityLabel: AppLocalizations.of(context).quantityL,
    );
    if (result == null) return;
    await _run(
      () => ref.read(deliveryStaffApiProvider).markDelivered(
            widget.deliveryId,
            finalDeliveredQuantity: result.quantity,
            notes: result.notes,
          ),
    );
  }

  Future<void> _addExtra() async {
    final result = await _promptQuantityAndNotes(
      title: AppLocalizations.of(context).extraMilk,
      quantityLabel: AppLocalizations.of(context).quantityL,
      requireQuantity: true,
      notesLabel: AppLocalizations.of(context).notesOptional,
    );
    if (result == null || result.quantity == null) return;
    await _run(
      () => ref.read(deliveryStaffApiProvider).addExtra(
            widget.deliveryId,
            extraQuantity: result.quantity!,
            reason: result.notes,
          ),
    );
  }

  Future<void> _skip() async {
    final notes = await _promptNotes(title: AppLocalizations.of(context).skip);
    if (notes == null) return;
    await _run(() => ref
        .read(deliveryStaffApiProvider)
        .skip(widget.deliveryId, notes: notes));
  }

  Future<void> _fail() async {
    final notes =
        await _promptNotes(title: AppLocalizations.of(context).failed);
    if (notes == null) return;
    await _run(() => ref
        .read(deliveryStaffApiProvider)
        .fail(widget.deliveryId, notes: notes));
  }

  Future<void> _cancel() async {
    final notes =
        await _promptNotes(title: AppLocalizations.of(context).cancel);
    if (notes == null) return;
    await _run(() => ref
        .read(deliveryStaffApiProvider)
        .cancel(widget.deliveryId, notes: notes));
  }

  Future<_QtyNotesResult?> _promptQuantityAndNotes({
    required String title,
    String? quantityLabel,
    bool requireQuantity = false,
    String? notesLabel,
  }) async {
    final qtyController = TextEditingController();
    final notesController = TextEditingController();
    try {
      final result = await showDialog<_QtyNotesResult>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (quantityLabel != null)
                TextField(
                  controller: qtyController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: quantityLabel),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                    labelText: notesLabel ??
                        AppLocalizations.of(context).notesOptional),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(AppLocalizations.of(context).cancel)),
            FilledButton(
              onPressed: () {
                if (requireQuantity &&
                    double.tryParse(qtyController.text.trim()) == null) {
                  return;
                }
                Navigator.of(ctx).pop(
                  _QtyNotesResult(
                    quantity: qtyController.text.trim().isEmpty
                        ? null
                        : qtyController.text.trim(),
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  ),
                );
              },
              child: Text(AppLocalizations.of(context).confirm),
            ),
          ],
        ),
      );
      // Let the dialog route + mouse tracker finish before we rebuild the page.
      FocusManager.instance.primaryFocus?.unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return result;
    } finally {
      qtyController.dispose();
      notesController.dispose();
    }
  }

  Future<String?> _promptNotes({required String title}) async {
    final controller = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
                labelText: AppLocalizations.of(context).notesOptional),
            maxLines: 3,
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
      FocusManager.instance.primaryFocus?.unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (confirmed != true) return null;
      return controller.text.trim().isEmpty ? '' : controller.text.trim();
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryAsync = ref.watch(deliveryDetailProvider(widget.deliveryId));
    final eventsAsync = ref.watch(deliveryEventsProvider(widget.deliveryId));

    // Prefer freshly mutated / refetched data over the stale route `initial`.
    final DeliveryModel? delivery = deliveryAsync.asData?.value ??
        _latest ??
        (deliveryAsync.isLoading || deliveryAsync.hasError
            ? widget.initial
            : null);

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(AppLocalizations.of(context).delivery)),
      body: delivery != null
          ? _body(delivery, eventsAsync)
          : deliveryAsync.when(
              data: (d) => _body(d, eventsAsync),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ListView(
                children: [
                  const SizedBox(height: 80),
                  DkEmpty(
                    message:
                        '${AppLocalizations.of(context).couldNotLoad}.\n$e',
                    actionLabel: AppLocalizations.of(context).retry,
                    onAction: () => ref
                        .invalidate(deliveryDetailProvider(widget.deliveryId)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _body(
      DeliveryModel d, AsyncValue<List<DeliveryEventModel>> eventsAsync) {
    final color = deliveryStatusColor(d.status);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(deliveryDetailProvider(widget.deliveryId));
        ref.invalidate(deliveryEventsProvider(widget.deliveryId));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  d.customerName ?? AppLocalizations.of(context).customer,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800, color: Dk.of(context).ink),
                ),
              ),
              Chip(
                label: Text(
                  d.status.replaceAll('_', ' '),
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                backgroundColor: color.withValues(alpha: 0.12),
                side: BorderSide.none,
              ),
              if (d.isEdited) ...[
                const SizedBox(width: 6),
                Chip(
                  label: Text(
                    AppLocalizations.of(context).edit,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                  backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                ),
              ],
            ],
          ),
          if ((d.address ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(d.address!, style: TextStyle(color: Dk.of(context).muted)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => LaunchHelpers.call(context, d.mobileNumber),
                  icon: Icon(Icons.call_outlined),
                  label: Text(AppLocalizations.of(context).call),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      LaunchHelpers.openMap(context, address: d.address),
                  icon: const Icon(Icons.map_outlined),
                  label: Text(AppLocalizations.of(context).map),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Dk.of(context).milkWhite,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                if ((d.productName ?? '').isNotEmpty)
                  _Row(AppLocalizations.of(context).products, d.productName!),
                _Row(
                  AppLocalizations.of(context).rate,
                  '${formatRupees(num.tryParse(d.ratePerLitre) ?? 0)}/L',
                ),
                _Row(AppLocalizations.of(context).delivery,
                    formatLitresString(d.scheduledQuantity)),
                _Row(AppLocalizations.of(context).extra,
                    formatLitresString(d.customerExtraQuantity)),
                _Row(AppLocalizations.of(context).extra,
                    formatLitresString(d.staffExtraQuantity)),
                const Divider(),
                _Row(AppLocalizations.of(context).total,
                    formatLitresString(d.expectedQuantity),
                    emphasize: true),
                _Row(AppLocalizations.of(context).amount,
                    formatRupees(num.tryParse(d.amount) ?? 0),
                    emphasize: true),
              ],
            ),
          ),
          if ((d.deliveryNotes ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text("${AppLocalizations.of(context).notes}: ${d.deliveryNotes}",
                style: TextStyle(color: Dk.of(context).muted)),
          ],
          const SizedBox(height: 20),
          if (d.isOpen || d.isDelivered) ...[
            // Keep one stable Wrap so status changes don't dispose the whole
            // action row under the mouse cursor (macOS mouse_tracker asserts).
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (d.isPending)
                  FilledButton.icon(
                    onPressed: _busy ? null : _outForDelivery,
                    icon: Icon(Icons.local_shipping_outlined),
                    label: Text(AppLocalizations.of(context).outForDelivery),
                  ),
                if (d.isOpen)
                  FilledButton.icon(
                    onPressed: _busy ? null : _markDelivered,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(AppLocalizations.of(context).markDelivered),
                  ),
                if (d.isDelivered)
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => context.push(
                              AppRoutes.deliveryDeliveryEdit(d.id),
                            ),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(AppLocalizations.of(context).edit),
                  ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _addExtra,
                  icon: const Icon(Icons.add),
                  label: Text(AppLocalizations.of(context).extra),
                ),
                if (d.isOpen)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _skip,
                    icon: const Icon(Icons.remove_circle_outline),
                    label: Text(AppLocalizations.of(context).skip),
                  ),
                if (d.isOpen)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _cancel,
                    icon: const Icon(Icons.cancel_outlined),
                    label: Text(AppLocalizations.of(context).cancel),
                  ),
                if (d.isOpen)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _fail,
                    icon: const Icon(Icons.error_outline),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger),
                    label: Text(AppLocalizations.of(context).failed),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          Text(AppLocalizations.of(context).history,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          eventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return Text(AppLocalizations.of(context).emptyDefault,
                    style: TextStyle(color: Dk.of(context).muted));
              }
              return Column(
                children: [
                  for (final e in events.reversed)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.circle,
                          size: 8, color: AppColors.teal),
                      title: Text(e.eventType.replaceAll('_', ' ')),
                      subtitle: Text(formatDateTime(e.createdAt)),
                    ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) =>
                Text('$e', style: const TextStyle(color: AppColors.danger)),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Dk.of(context).muted)),
          Text(
            value,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.leafDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyNotesResult {
  const _QtyNotesResult({this.quantity, this.notes});
  final String? quantity;
  final String? notes;
}
