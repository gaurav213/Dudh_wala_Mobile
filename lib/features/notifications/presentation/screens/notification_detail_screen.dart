import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../delivery_staff/presentation/providers/delivery_staff_providers.dart';
import '../../data/models/notification_detail_models.dart';
import '../providers/notifications_providers.dart';
import '../utils/resolve_notification_copy.dart';

class NotificationDetailScreen extends ConsumerWidget {
  const NotificationDetailScreen({super.key, required this.recipientId});

  final String recipientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(notificationDetailProvider(recipientId));

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(l10n.notifGenericTitle)),
      body: detail.when(
        data: (d) => _DetailBody(detail: d, recipientId: recipientId),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DkEmpty(
          message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
          actionLabel: l10n.back,
          onAction: () => context.pop(),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.detail, required this.recipientId});

  final NotificationDetailModel detail;
  final String recipientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = resolveNotificationCopy(
      Localizations.localeOf(context).languageCode,
      title: detail.title,
      body: detail.body,
      type: detail.type,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          copy.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Dk.of(context).ink,
              ),
        ),
        const SizedBox(height: 8),
        Text(copy.body, style: TextStyle(color: Dk.of(context).muted)),
        if (detail.createdAt != null) ...[
          const SizedBox(height: 8),
          Text(
            formatDateTime(detail.createdAt!),
            style: TextStyle(color: Dk.of(context).muted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 20),
        switch (detail.context) {
          PaymentNotificationContext c => _PaymentCard(
              payment: c,
              recipientId: recipientId,
            ),
          DeliveryNotificationContext c => _DeliveryCard(delivery: c),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Dk.of(context).milkWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: Dk.of(context).muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Dk.of(context).ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends ConsumerWidget {
  const _PaymentCard({
    required this.payment,
    required this.recipientId,
  });

  final PaymentNotificationContext payment;
  final String recipientId;

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(deliveryStaffApiProvider).confirmCash(payment.paymentId);
      invalidateNotifications(ref);
      ref.invalidate(notificationDetailProvider(recipientId));
      await refreshDeliveryStaffData(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.notifCashConfirmedTitle)),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final notesController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).rejectCashClaim),
        content: TextField(
          controller: notesController,
          decoration: InputDecoration(labelText: l10n.notesOptional),
          maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.reject)),
        ],
      ),
    );
    if (ok != true) {
      notesController.dispose();
      return;
    }
    try {
      final notes = notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim();
      await ref.read(deliveryStaffApiProvider).rejectCash(
            payment.paymentId,
            notes: notes,
          );
      invalidateNotifications(ref);
      ref.invalidate(notificationDetailProvider(recipientId));
      await refreshDeliveryStaffData(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.notifCashRejectedTitle)),
        );
        context.pop();
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
    final amount = num.tryParse(payment.amount) ?? 0;
    final imageUrl = mediaUrl(payment.proofImageUrl);

    return _DetailCard(
      children: [
        Text(
          formatRupees(amount),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Dk.of(context).ink,
              ),
        ),
        const SizedBox(height: 12),
        if (payment.customerName != null)
          _DetailRow(label: l10n.customer, value: payment.customerName!),
        _DetailRow(
            label: l10n.status, value: _friendlyPaymentStatus(payment.status)),
        if (payment.paymentDate.isNotEmpty)
          _DetailRow(
            label: l10n.day,
            value: formatDate(
              DateTime.tryParse(payment.paymentDate) ?? DateTime.now(),
            ),
          ),
        if (payment.purpose != null && payment.purpose!.isNotEmpty)
          _DetailRow(label: 'Purpose', value: payment.purpose!),
        _DetailRow(label: l10n.payment, value: payment.paymentMethod),
        if (payment.notes != null && payment.notes!.trim().isNotEmpty)
          _DetailRow(label: l10n.notes, value: payment.notes!.trim()),
        if (payment.rejectionNote != null &&
            payment.rejectionNote!.trim().isNotEmpty)
          _DetailRow(label: 'Rejection', value: payment.rejectionNote!.trim()),
        if (imageUrl != null) ...[
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context).paymentProof, style: TextStyle(color: Dk.of(context).muted)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ],
        if (payment.canConfirmCash || payment.canRejectCash) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              if (payment.canRejectCash)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _reject(context, ref),
                    child: Text(l10n.reject),
                  ),
                ),
              if (payment.canConfirmCash && payment.canRejectCash)
                const SizedBox(width: 10),
              if (payment.canConfirmCash)
                Expanded(
                  child: FilledButton(
                    onPressed: () => _confirm(context, ref),
                    child: Text(l10n.confirm),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.delivery});

  final DeliveryNotificationContext delivery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final qty = num.tryParse(delivery.quantity) ?? 0;
    final amount = num.tryParse(delivery.amount) ?? 0;

    return _DetailCard(
      children: [
        if (delivery.customerName != null)
          _DetailRow(label: l10n.customer, value: delivery.customerName!),
        if (delivery.deliveryDate.isNotEmpty)
          _DetailRow(
            label: l10n.day,
            value: formatDate(
              DateTime.tryParse(delivery.deliveryDate) ?? DateTime.now(),
            ),
          ),
        _DetailRow(label: l10n.shift, value: delivery.deliveryShift),
        _DetailRow(label: l10n.quantityL, value: formatLitres(qty)),
        _DetailRow(label: l10n.amount, value: formatRupees(amount)),
        _DetailRow(label: l10n.status, value: delivery.status),
        _DetailRow(label: 'Confirmation', value: delivery.confirmationStatus),
      ],
    );
  }
}

String _friendlyPaymentStatus(String raw) {
  return switch (raw) {
    'PENDING_CONFIRMATION' => 'Awaiting confirmation',
    'CONFIRMED' => 'Confirmed',
    'REJECTED' => 'Rejected',
    _ => raw.replaceAll('_', ' ').toLowerCase(),
  };
}
