import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/farm_models.dart';
import '../providers/farm_providers.dart';

class FarmStaffScreen extends ConsumerWidget {
  const FarmStaffScreen({super.key});

  Future<void> _openInviteDialog(
      BuildContext context, WidgetRef ref, String farmId) async {
    final l10n = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final mobile = TextEditingController();
    final name = TextEditingController();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text("${l10n.invite} ${l10n.navDeliveryStaff}"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: mobile,
                  decoration: InputDecoration(
                      labelText: l10n.mobileNumber, prefixText: '+91 '),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? 'Enter a valid number'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: name,
                  decoration:
                      InputDecoration(labelText: AppLocalizations.of(context).nameOptional),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  saving ? null : () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => saving = true);
                      try {
                        await ref.read(farmApiProvider).inviteStaff(
                              farmId,
                              mobileNumber: mobile.text.trim(),
                              name: name.text.trim(),
                            );
                        ref.invalidate(farmStaffInvitationsProvider);
                        invalidateFarmDashboard(ref);
                        if (dialogContext.mounted)
                          Navigator.of(dialogContext).pop();
                      } catch (e) {
                        setState(() => saving = false);
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext)
                              .showSnackBar(SnackBar(content: Text('$e')));
                        }
                      }
                    },
              child: Text(saving ? l10n.loading : l10n.invite),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _invitationAction(
    WidgetRef ref,
    BuildContext context,
    String farmId,
    FarmStaffInvitationModel invite,
    String action,
  ) async {
    try {
      if (action == 'resend') {
        await ref
            .read(farmApiProvider)
            .resendStaffInvitation(farmId, invite.id);
      } else {
        await ref
            .read(farmApiProvider)
            .cancelStaffInvitation(farmId, invite.id);
      }
      ref.invalidate(farmStaffInvitationsProvider);
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
    final farmIdAsync = ref.watch(currentFarmIdProvider);
    final membersAsync = ref.watch(farmStaffMembersProvider);
    final invitationsAsync = ref.watch(farmStaffInvitationsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: farmIdAsync.maybeWhen(
        data: (farmId) => FloatingActionButton(
          onPressed: () => _openInviteDialog(context, ref, farmId),
          child: const Icon(Icons.person_add_alt_1),
        ),
        orElse: () => null,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(farmStaffMembersProvider);
          ref.invalidate(farmStaffInvitationsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(AppLocalizations.of(context).members, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            membersAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(AppLocalizations.of(context).noStaffMembersYet,
                        style: TextStyle(color: Dk.of(context).muted)),
                  );
                }
                return Column(
                  children: members
                      .map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            tileColor: Dk.of(context).milkWhite,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            leading: Icon(
                              m.isOwner ? Icons.star : Icons.badge_outlined,
                              color: m.isActive
                                  ? AppColors.teal
                                  : Dk.of(context).muted,
                            ),
                            title: Text(m.userName ?? m.userMobile ?? m.userId),
                            subtitle: Text("${m.memberRole} · ${m.status}"),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: m.isOwner
                                ? null
                                : () => context.push(
                                      AppRoutes.farmStaffDetail(m.userId),
                                    ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text('$e', style: TextStyle(color: AppColors.danger)),
            ),
            const SizedBox(height: 24),
            Text("${l10n.pending} ${l10n.invitations}",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            invitationsAsync.when(
              data: (invites) {
                if (invites.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(AppLocalizations.of(context).noInvitationsSent,
                        style: TextStyle(color: Dk.of(context).muted)),
                  );
                }
                return Column(
                  children: invites
                      .map(
                        (inv) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            tileColor: Dk.of(context).milkWhite,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            leading: const Icon(Icons.mail_outline,
                                color: AppColors.warning),
                            title: Text(inv.name ?? inv.mobileNumber),
                            subtitle:
                                Text("${inv.mobileNumber} · ${inv.status}"),
                            trailing: inv.isPending
                                ? PopupMenuButton<String>(
                                    onSelected: (action) =>
                                        farmIdAsync.whenData(
                                      (farmId) => _invitationAction(
                                          ref, context, farmId, inv, action),
                                    ),
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                          value: 'resend',
                                          child: Text(AppLocalizations.of(context).resend)),
                                      PopupMenuItem(
                                          value: 'cancel',
                                          child: Text(l10n.cancel)),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text('$e', style: const TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      ),
    );
  }
}
