import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../app/routes.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/app_prefs_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _openEditProfile(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email ?? '');
    var busy = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> save() async {
              if (busy || !(formKey.currentState?.validate() ?? false)) return;
              setSheetState(() => busy = true);
              try {
                await ref.read(authControllerProvider.notifier).updateProfile(
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.saved)),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              } finally {
                if (ctx.mounted) setSheetState(() => busy = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.editProfile,
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.name,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty) return l10n.nameRequired;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: l10n.emailOptional,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        final email = (v ?? '').trim();
                        if (email.isEmpty) return null;
                        if (!email.contains('@') || !email.contains('.')) {
                          return l10n.pleaseTryAgain;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: busy ? null : save,
                      icon: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(busy ? l10n.saving : l10n.save),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // Sheet may still animate out; dispose next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nameCtrl.dispose();
        emailCtrl.dispose();
      });
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prefs = ref.watch(appPrefsProvider);
    final role = ref.watch(authControllerProvider).user?.role;
    final showSyncTools =
        role == UserRole.farmOwner || role == UserRole.platformOwner;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.editProfile),
            subtitle: Text("${l10n.name} · ${l10n.emailOptional}"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openEditProfile(context, ref),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.appearance,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          RadioGroup<ThemeMode>(
            groupValue: prefs.themeMode,
            onChanged: (mode) {
              if (mode != null) {
                ref.read(appPrefsProvider.notifier).setThemeMode(mode);
              }
            },
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(l10n.themeLight),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l10n.themeDark),
                  value: ThemeMode.dark,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l10n.themeSystem),
                  subtitle: Text(l10n.themeSystemHint),
                  value: ThemeMode.system,
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.language,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          RadioGroup<String>(
            groupValue: prefs.locale.languageCode,
            onChanged: (code) {
              if (code != null) {
                ref.read(appPrefsProvider.notifier).setLocaleCode(code);
              }
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text(l10n.langEnglish),
                  value: 'en',
                ),
                RadioListTile<String>(
                  title: Text(l10n.langHindi),
                  value: 'hi',
                ),
                RadioListTile<String>(
                  title: Text(l10n.langMarathi),
                  value: 'mr',
                ),
              ],
            ),
          ),
          if (showSyncTools) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.sync),
              title: Text(l10n.syncStatus),
              onTap: () => context.push(AppRoutes.syncStatus),
            ),
            ListTile(
              leading: const Icon(Icons.merge_type),
              title: Text(l10n.conflictResolution),
              onTap: () => context.push(AppRoutes.conflicts),
            ),
          ],
          if (role != UserRole.customer) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(l10n.profile),
              onTap: () {
                if (role == UserRole.deliveryStaff) {
                  context.go(AppRoutes.deliveryProfile);
                } else {
                  context.go(AppRoutes.profile);
                }
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error),
            title: Text(
              l10n.deleteAccount,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _confirmDeleteAccount(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    var busy = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(l10n.deleteAccountConfirmTitle),
              content: Text(l10n.deleteAccountConfirmMessage),
              actions: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.of(ctx).pop(false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error,
                  ),
                  onPressed: busy
                      ? null
                      : () async {
                          setDialogState(() => busy = true);
                          try {
                            await ref
                                .read(authControllerProvider.notifier)
                                .deleteAccount();
                            if (ctx.mounted) Navigator.of(ctx).pop(true);
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                              setDialogState(() => busy = false);
                            }
                          }
                        },
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.deleteAccountConfirmAction),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountDeleted)),
      );
      context.go(AppRoutes.login);
    }
  }
}
