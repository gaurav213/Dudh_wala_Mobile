import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/utils/media_url.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/confirm_logout.dart';
import '../../../customer_marketplace/presentation/providers/customer_marketplace_providers.dart';
import '../../../../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  var _avatarBusy = false;

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _avatarBusy = true);
    try {
      await ref.read(authControllerProvider.notifier).uploadAvatar(picked.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).profilePhotoUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final isCustomer = user?.role == UserRole.customer;
    final addressesAsync =
        isCustomer ? ref.watch(customerAddressesProvider) : null;
    final avatar = mediaUrl(user?.avatarUrl);

    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(AppLocalizations.of(context).profile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Dk.of(context).milkWhite,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Dk.of(context).foam,
                      backgroundImage:
                          avatar != null ? NetworkImage(avatar) : null,
                      child: avatar == null
                          ? Text(
                              user?.initials ?? '?',
                              style: TextStyle(
                                color: Dk.of(context).ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: AppColors.leaf,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _avatarBusy ? null : _pickAvatar,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: _avatarBusy
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? AppLocalizations.of(context).account,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Dk.of(context).ink,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatPhoneIn(user?.phone ?? ''),
                        style: TextStyle(color: Dk.of(context).muted),
                      ),
                      if ((user?.email ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user!.email!,
                          style: TextStyle(color: Dk.of(context).muted),
                        ),
                      ],
                      TextButton(
                        onPressed: _avatarBusy ? null : _pickAvatar,
                        child: Text(AppLocalizations.of(context).changePhoto),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isCustomer) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  AppLocalizations.of(context).addresses,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Dk.of(context).ink,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push(AppRoutes.customerAddresses),
                  child: Text(AppLocalizations.of(context).manage),
                ),
              ],
            ),
            const SizedBox(height: 4),
            addressesAsync!.when(
              data: (list) {
                if (list.isEmpty) {
                  return _LinkTile(
                    icon: Icons.add_location_alt_outlined,
                    title: AppLocalizations.of(context).addDeliveryAddress,
                    onTap: () => context.push(AppRoutes.customerAddresses),
                  );
                }
                return Column(
                  children: [
                    for (final a in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          tileColor: Dk.of(context).milkWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: Icon(
                            a.isDefault
                                ? Icons.home
                                : Icons.location_on_outlined,
                            color: AppColors.leaf,
                          ),
                          title: Text(
                            a.label,
                            style: TextStyle(
                              color: Dk.of(context).ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            [
                              a.addressLine1,
                              if ((a.addressLine2 ?? '').isNotEmpty)
                                a.addressLine2,
                              '${a.area}, ${a.city}',
                              '${a.state} ${a.postalCode}',
                            ].join('\n'),
                            style: TextStyle(color: Dk.of(context).muted),
                          ),
                          isThreeLine: true,
                          trailing: a.isDefault
                              ? Chip(
                                  label: Text(AppLocalizations.of(context).defaultLabel),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: Dk.of(context).foam,
                                )
                              : null,
                          onTap: () =>
                              context.push(AppRoutes.customerAddresses),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Text(
                AppLocalizations.of(context).couldNotLoadAddresses,
                style: TextStyle(color: Dk.of(context).muted),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _LinkTile(
            icon: Icons.settings_outlined,
            title: AppLocalizations.of(context).settings,
            onTap: () => context.push(AppRoutes.settings),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => confirmAndLogout(context, ref),
            icon: const Icon(Icons.logout),
            label: Text(AppLocalizations.of(context).signOut),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        tileColor: Dk.of(context).milkWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: AppColors.leaf),
        title: Text(title, style: TextStyle(color: Dk.of(context).ink)),
        trailing: Icon(Icons.chevron_right, color: Dk.of(context).muted),
        onTap: onTap,
      ),
    );
  }
}
