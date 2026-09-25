import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/utils/delivery_shift_helpers.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/farm_providers.dart';

class FarmRequestDetailScreen extends ConsumerStatefulWidget {
  const FarmRequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<FarmRequestDetailScreen> createState() =>
      _FarmRequestDetailScreenState();
}

class _FarmRequestDetailScreenState
    extends ConsumerState<FarmRequestDetailScreen> {
  bool _busy = false;
  String? _busyLabel;

  Future<void> _run(
    Future<void> Function() action, {
    required String label,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _busyLabel = label;
    });
    try {
      await action();
      ref.invalidate(farmServiceRequestDetailProvider(widget.requestId));
      ref.invalidate(farmServiceRequestsProvider);
      await refreshFarmDashboard(ref);
      try {
        await ref.read(farmServiceRequestsProvider.future);
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyLabel = null;
        });
      }
    }
  }

  Future<void> _confirmCancel(String farmId) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelRequestTitle),
        content: Text(l10n.cancelRequestBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).keepRequest),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.cancelRequest),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(
      () => ref
          .read(farmApiProvider)
          .cancelServiceRequest(farmId, widget.requestId),
      label: 'Cancelling…',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notifServiceRequestCancelledTitle)),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(farmServiceRequestDetailProvider(widget.requestId));
    final farmId = ref.watch(currentFarmIdProvider).asData?.value;

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(l10n.requests)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DkEmpty(
          message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
          actionLabel: l10n.back,
          onAction: () => context.pop(),
        ),
        data: (request) {
          final avatar = mediaUrl(request.customerAvatarUrl);
          final accent =
              request.isPending ? AppColors.warning : AppColors.success;
          final rating = request.customerAverageRating;
          final ratingLine = rating != null
              ? '${rating.toStringAsFixed(1)} ★ · ${request.customerReviewCount} reviews'
              : 'No ratings yet';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Dk.of(context).milkWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(left: BorderSide(color: accent, width: 4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage:
                              avatar != null ? NetworkImage(avatar) : null,
                          child: avatar == null
                              ? Text(
                                  ((request.customerName ?? '?').trim().isEmpty
                                          ? '?'
                                          : request.customerName!.trim()[0])
                                      .toUpperCase(),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.customerName ?? l10n.customer,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              Text(ratingLine,
                                  style:
                                      TextStyle(color: Dk.of(context).muted)),
                              if ((request.customerMobileNumber ?? '')
                                  .isNotEmpty)
                                Text(request.customerMobileNumber!,
                                    style:
                                        TextStyle(color: Dk.of(context).muted)),
                            ],
                          ),
                        ),
                        Text(
                          request.isPending ? l10n.pending : request.status,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(request.productName ?? l10n.milk,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(
                      [
                        formatLitresString(request.quantity),
                        request.scheduleLabel,
                        deliveryShiftLabel(request.deliveryShift),
                      ].join(' · '),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).startDateLabel(request.preferredStartDate),
                      style: TextStyle(color: Dk.of(context).muted),
                    ),
                    Text(
                      request.isAccepted
                          ? 'Accepted ${formatRelativeTime(request.createdAt)}'
                          : 'Requested ${formatRelativeTime(request.createdAt)}',
                      style: TextStyle(color: Dk.of(context).muted),
                    ),
                    if ((request.addressSummary ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(request.addressSummary!),
                    ],
                    if ((request.deliveryInstructions ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(request.deliveryInstructions!),
                    ],
                  ],
                ),
              ),
              if (request.isPending && farmId != null) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _run(
                            () => ref
                                .read(farmApiProvider)
                                .acceptServiceRequest(farmId, request.id),
                            label: 'Accepting…',
                          ),
                  child: Text(_busyLabel == 'Accepting…'
                      ? 'Accepting…'
                      : 'Accept Request'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy ? null : () => _confirmCancel(farmId),
                  child: Text(_busyLabel == 'Cancelling…'
                      ? 'Cancelling…'
                      : 'Cancel Request'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
