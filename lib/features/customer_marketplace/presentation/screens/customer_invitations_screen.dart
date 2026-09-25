import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/models/marketplace_models.dart';
import '../../../../core/utils/delivery_shift_helpers.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/customer_marketplace_providers.dart';

class CustomerInvitationsScreen extends ConsumerWidget {
  const CustomerInvitationsScreen({super.key});

  Future<void> _respond(
      WidgetRef ref, BuildContext context, String id, bool accept) async {
    try {
      final api = ref.read(customerMarketplaceApiProvider);
      if (accept) {
        await api.acceptInvitation(id);
      } else {
        await api.rejectInvitation(id);
      }
      ref.invalidate(customerInvitationsProvider);
      try {
        await ref.read(customerInvitationsProvider.future);
      } catch (_) {}
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? AppLocalizations.of(context).invitationAccepted
                  : AppLocalizations.of(context).invitationDeclined,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final invitationsAsync = ref.watch(customerInvitationsProvider);

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(l10n.invitations)),
      body: invitationsAsync.when(
        data: (invitations) {
          if (invitations.isEmpty) {
            return DkEmpty(
              message: l10n.noFarmInvitationsYet,
              actionLabel: l10n.findFarms,
              onAction: () => context.push(AppRoutes.customerFindFarms),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(customerInvitationsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: invitations.length,
              itemBuilder: (context, i) {
                final inv = invitations[i];
                return _InvitationTile(
                  invitation: inv,
                  onAccept: inv.isPending && !inv.isExpired
                      ? () => _respond(ref, context, inv.id, true)
                      : null,
                  onReject: inv.isPending && !inv.isExpired
                      ? () => _respond(ref, context, inv.id, false)
                      : null,
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DkEmpty(
          message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(customerInvitationsProvider),
        ),
      ),
    );
  }
}

class _InvitationTile extends StatelessWidget {
  const _InvitationTile(
      {required this.invitation, this.onAccept, this.onReject});

  final CustomerInvitationModel invitation;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Dk.of(context).milkWhite,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  invitation.farmName ?? AppLocalizations.of(context).farmInvitation,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              Chip(
                label: Text(invitation.status,
                    style: const TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
                backgroundColor: Dk.of(context).foam,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "${invitation.productName ?? invitation.milkType ?? AppLocalizations.of(context).milk} · ${formatLitresString(invitation.quantity)} · ${deliveryShiftLabel(invitation.deliveryShift, AppLocalizations.of(context))} · ₹${invitation.proposedRate}/${AppLocalizations.of(context).litres}",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context).startingDate(invitation.preferredStartDate),
              style: TextStyle(color: Dk.of(context).muted)),
          if (onAccept != null || onReject != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (onReject != null)
                  Expanded(
                    child: OutlinedButton(
                        onPressed: onReject, child: Text(l10n.decline)),
                  ),
                if (onAccept != null && onReject != null)
                  const SizedBox(width: 10),
                if (onAccept != null)
                  Expanded(
                    child: FilledButton(
                        onPressed: onAccept, child: Text(l10n.accept)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
