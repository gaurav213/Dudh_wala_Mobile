import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/l10n/delivery_labels.dart';
import '../../../../core/models/marketplace_models.dart';
import '../../../../core/utils/delivery_schedule_helpers.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/customer_marketplace_providers.dart';

/// One Inbox for every customer: farm invitations + your milk requests together.
class CustomerRequestsScreen extends ConsumerStatefulWidget {
  const CustomerRequestsScreen({super.key, this.focusRequestId});

  final String? focusRequestId;

  @override
  ConsumerState<CustomerRequestsScreen> createState() =>
      _CustomerRequestsScreenState();
}

class _CustomerRequestsScreenState
    extends ConsumerState<CustomerRequestsScreen> {
  String? _cancellingId;
  String? _inviteBusyId;
  final Map<String, GlobalKey> _keys = {};
  String? _highlightId;
  bool _didFocus = false;

  GlobalKey _keyFor(String id) =>
      _keys.putIfAbsent(id, () => GlobalKey(debugLabel: 'inbox-$id'));

  Future<void> _refresh() async {
    // Refresh independently so one failing endpoint cannot wipe the other.
    ref.invalidate(customerInvitationsProvider);
    ref.invalidate(customerServiceRequestsProvider);
    await Future.wait([
      ref
          .read(customerInvitationsProvider.future)
          .then<void>((_) {}, onError: (_) {}),
      ref
          .read(customerServiceRequestsProvider.future)
          .then<void>((_) {}, onError: (_) {}),
    ]);
  }

  Future<void> _cancelRequest(String id) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelRequestTitle),
        content: Text(l10n.cancelRequestBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).keep),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.cancelRequest),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _cancellingId = id);
    try {
      await ref.read(customerMarketplaceApiProvider).cancelServiceRequest(id);
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }
  }

  Future<void> _respondInvitation(String id, bool accept) async {
    setState(() => _inviteBusyId = id);
    try {
      final api = ref.read(customerMarketplaceApiProvider);
      if (accept) {
        await api.acceptInvitation(id);
      } else {
        await api.rejectInvitation(id);
      }
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(accept
                    ? AppLocalizations.of(context).invitationAccepted
                    : AppLocalizations.of(context).invitationDeclined),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _inviteBusyId = null);
    }
  }

  void _tryFocus() {
    final focusId = widget.focusRequestId;
    if (_didFocus || focusId == null || focusId.isEmpty) return;
    _didFocus = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ctx = _keyFor(focusId).currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          alignment: 0.15,
          curve: Curves.easeOut,
        );
      }
      if (!mounted) return;
      setState(() => _highlightId = focusId);
      await Future<void>.delayed(const Duration(milliseconds: 2500));
      if (mounted && _highlightId == focusId) {
        setState(() => _highlightId = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final invitationsAsync = ref.watch(customerInvitationsProvider);
    final requestsAsync = ref.watch(customerServiceRequestsProvider);

    // Riverpod 2.6: AsyncValue.value THROWS on error when there is no prior
    // data — that crashed Inbox whenever the API blipped. Always use valueOrNull.
    final invitations =
        invitationsAsync.valueOrNull ?? const <CustomerInvitationModel>[];
    final requests = requestsAsync.valueOrNull ?? const <ServiceRequestModel>[];
    final invError = invitationsAsync.hasError ? invitationsAsync.error : null;
    final reqError = requestsAsync.hasError ? requestsAsync.error : null;
    final loading =
        (invitationsAsync.isLoading && invitationsAsync.valueOrNull == null) ||
            (requestsAsync.isLoading && requestsAsync.valueOrNull == null);

    final items = <_InboxItem>[
      for (final inv in invitations) _InboxItem.invitation(inv),
      for (final req in requests) _InboxItem.request(req),
    ]..sort((a, b) => b.sortAt.compareTo(a.sortAt));

    final isEmpty = items.isEmpty;
    final loadError = reqError ?? invError;

    if (!loading && items.isNotEmpty && widget.focusRequestId != null) {
      _tryFocus();
    }

    Widget body;
    if (loading && isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (isEmpty && loadError != null) {
      body = DkEmpty(
        message: '${AppLocalizations.of(context).couldNotLoad}.\n$loadError',
        actionLabel: l10n.retry,
        onAction: _refresh,
      );
    } else if (isEmpty) {
      body = DkEmpty(
        message: l10n.inboxEmpty,
        actionLabel: l10n.findFarms,
        onAction: () => context.push(AppRoutes.customerFindFarms),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (loadError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  AppLocalizations.of(context).inboxPartialMissing,
                  style: TextStyle(
                    color: Dk.of(context).muted,
                    fontSize: 12,
                  ),
                ),
              ),
            for (final item in items)
              if (item.invitation != null)
                _InvitationCard(
                  key: ValueKey('inv-${item.invitation!.id}'),
                  invitation: item.invitation!,
                  busy: _inviteBusyId == item.invitation!.id,
                  onAccept:
                      item.invitation!.isPending && !item.invitation!.isExpired
                          ? () => _respondInvitation(item.invitation!.id, true)
                          : null,
                  onReject:
                      item.invitation!.isPending && !item.invitation!.isExpired
                          ? () => _respondInvitation(item.invitation!.id, false)
                          : null,
                )
              else
                KeyedSubtree(
                  key: _keyFor(item.request!.id),
                  child: _RequestCard(
                    key: ValueKey('req-${item.request!.id}'),
                    request: item.request!,
                    highlighted: _highlightId == item.request!.id,
                    cancelling: _cancellingId == item.request!.id,
                    onCancel: item.request!.isPending
                        ? () => _cancelRequest(item.request!.id)
                        : null,
                  ),
                ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(l10n.navInbox)),
      body: body,
    );
  }
}

class _InboxItem {
  _InboxItem.invitation(CustomerInvitationModel inv)
      : invitation = inv,
        request = null,
        sortAt = inv.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  _InboxItem.request(ServiceRequestModel req)
      : invitation = null,
        request = req,
        sortAt = req.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  final CustomerInvitationModel? invitation;
  final ServiceRequestModel? request;
  final DateTime sortAt;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    super.key,
    required this.invitation,
    this.onAccept,
    this.onReject,
    this.busy = false,
  });

  final CustomerInvitationModel invitation;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pending = invitation.isPending && !invitation.isExpired;
    final accent = pending ? AppColors.warning : Dk.of(context).muted;
    final statusLabel = pending
        ? l10n.pending
        : invitation.isExpired
            ? l10n.expired
            : invitation.status;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Dk.of(context).milkWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              invitation.farmName ?? l10n.farm,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(label: statusLabel, color: accent),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context).invitation,
                        style: TextStyle(
                          color: Dk.of(context).muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          invitation.productName ??
                              invitation.milkType ??
                              l10n.milk,
                          formatLitresString(invitation.quantity),
                          '₹${invitation.proposedRate}/${l10n.litres}',
                        ].join(' · '),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${l10n.startDateLabel(invitation.preferredStartDate)}${invitation.createdAt != null ? ' · ${l10n.invitedRelative(formatRelativeTime(invitation.createdAt))}' : ''}",
                        style: TextStyle(
                          color: Dk.of(context).muted,
                          fontSize: 12,
                        ),
                      ),
                      if (onAccept != null || onReject != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (onReject != null)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: busy ? null : onReject,
                                  child: Text(busy ? '…' : l10n.decline),
                                ),
                              ),
                            if (onAccept != null && onReject != null)
                              const SizedBox(width: 10),
                            if (onAccept != null)
                              Expanded(
                                child: FilledButton(
                                  onPressed: busy ? null : onAccept,
                                  child:
                                      Text(busy ? l10n.loading : l10n.accept),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    super.key,
    required this.request,
    this.highlighted = false,
    this.cancelling = false,
    this.onCancel,
  });

  final ServiceRequestModel request;
  final bool highlighted;
  final bool cancelling;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent = request.isPending
        ? AppColors.warning
        : request.isAccepted
            ? AppColors.success
            : Dk.of(context).muted;
    final statusLabel = request.isPending
        ? l10n.pending
        : request.isAccepted
            ? l10n.statusAccepted
            : request.status == 'CANCELLED'
                ? l10n.cancelled
                : request.status == 'REJECTED'
                    ? l10n.reject
                    : request.status;
    final farm = (request.farmName ?? '').trim().isNotEmpty
        ? request.farmName!.trim()
        : l10n.farm;
    final product =
        (request.productName ?? request.milkType ?? l10n.milk).trim();
    final shift = localizedDeliveryShift(l10n, request.deliveryShift);
    final start = request.preferredStartDate.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.warning.withValues(alpha: 0.12)
            : Dk.of(context).milkWhite,
        borderRadius: BorderRadius.circular(12),
        border: highlighted
            ? Border.all(color: AppColors.warning, width: 1.5)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              farm,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(label: statusLabel, color: accent),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context).yourRequest,
                        style: TextStyle(
                          color: Dk.of(context).muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$product · ${formatLitresString(request.quantity)}",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          deliveryScheduleLabel(request.scheduleType, l10n),
                          if (shift.isNotEmpty) shift,
                          if (start.isNotEmpty) l10n.startShort(start),
                        ].join(' · '),
                        style: TextStyle(
                          color: Dk.of(context).muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.isAccepted
                            ? l10n.approvedRelative(
                                formatRelativeTime(request.createdAt))
                            : l10n.requestedRelative(
                                formatRelativeTime(request.createdAt)),
                        style: TextStyle(
                          color: Dk.of(context).muted,
                          fontSize: 12,
                        ),
                      ),
                      if (request.isAccepted &&
                          ((request.firstDeliveryDate ?? '').isNotEmpty ||
                              (request.nextDeliveryDate ?? '').isNotEmpty)) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            if ((request.firstDeliveryDate ?? '').isNotEmpty)
                              l10n.firstDeliveryDateLabel(
                                  request.firstDeliveryDate!),
                            if ((request.nextDeliveryDate ?? '').isNotEmpty)
                              l10n.nextDeliveryDateLabel(
                                  request.nextDeliveryDate!),
                          ].join(' · '),
                          style: TextStyle(
                            color: Dk.of(context).muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (onCancel != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton(
                            onPressed: cancelling ? null : onCancel,
                            child: Text(
                              cancelling ? l10n.loading : l10n.cancelRequest,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
