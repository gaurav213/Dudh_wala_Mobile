import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/farm_providers.dart';

class FarmStaffSettingsScreen extends ConsumerStatefulWidget {
  const FarmStaffSettingsScreen({super.key, required this.staffUserId});

  final String staffUserId;

  @override
  ConsumerState<FarmStaffSettingsScreen> createState() =>
      _FarmStaffSettingsScreenState();
}

class _FarmStaffSettingsScreenState
    extends ConsumerState<FarmStaffSettingsScreen> {
  bool _busy = false;

  Future<void> _deactivate(String farmId, String memberId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).deactivateStaff),
        content: Text(AppLocalizations.of(context).deactivateStaffBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalizations.of(context).continueAction)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(farmApiProvider)
          .setMemberStatus(farmId, memberId, 'deactivate');
      ref.invalidate(farmStaffDetailProvider(widget.staffUserId));
      ref.invalidate(farmStaffMembersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).staffDeactivated)),
        );
        context.pop();
      }
    } catch (e) {
      final msg = '$e';
      if (msg.contains('PENDING_DELIVERIES') ||
          msg.contains('pending deliveries')) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text("${l10n.pending} ${l10n.deliveries}"),
            content: Text(
              msg.contains('has')
                  ? msg
                  : 'This staff member still has pending deliveries today.\n\n'
                      'Reassign those deliveries before deactivating.',
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel)),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context).reassignDeliveries),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(String farmId, String memberId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).removeStaff),
        content: Text(AppLocalizations.of(context).removeStaffBody,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context).remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(farmApiProvider)
          .setMemberStatus(farmId, memberId, 'remove');
      ref.invalidate(farmStaffMembersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).staffRemoved)),
        );
        context.go('/farm/staff');
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
    final detailAsync = ref.watch(farmStaffDetailProvider(widget.staffUserId));
    final farmIdAsync = ref.watch(currentFarmIdProvider);

    return Scaffold(
      appBar: AppBar(title: Text("${l10n.staff} ${l10n.settings}")),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DkEmpty(message: '$e'),
        data: (detail) {
          final farmId = farmIdAsync.valueOrNull;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(AppLocalizations.of(context).staffStatus,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ListTile(
                tileColor: Dk.of(context).milkWhite,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                title: Text(detail.profile.status),
                subtitle: Text(detail.profile.name),
              ),
              const SizedBox(height: 16),
              if (detail.profile.status == 'ACTIVE')
                FilledButton(
                  onPressed: _busy || farmId == null
                      ? null
                      : () => _deactivate(farmId, detail.memberId),
                  child: Text(AppLocalizations.of(context).deactivateStaff),
                )
              else
                FilledButton(
                  onPressed: _busy || farmId == null
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          try {
                            await ref.read(farmApiProvider).setMemberStatus(
                                  farmId,
                                  detail.memberId,
                                  'reactivate',
                                );
                            ref.invalidate(
                                farmStaffDetailProvider(widget.staffUserId));
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                  child: Text(AppLocalizations.of(context).reactivateStaff),
                ),
              const SizedBox(height: 32),
              Text(
                AppLocalizations.of(context).dangerZone,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red.shade700,
                    ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700),
                onPressed: _busy || farmId == null
                    ? null
                    : () => _remove(farmId, detail.memberId),
                child: Text(AppLocalizations.of(context).removeStaff),
              ),
            ],
          );
        },
      ),
    );
  }
}
