import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/branding/brand_logo.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/login_validators.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _farmName = TextEditingController();
  final _businessName = TextEditingController();
  final _address = TextEditingController();
  final _area = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postal = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _farmName.dispose();
    _businessName.dispose();
    _address.dispose();
    _area.dispose();
    _city.dispose();
    _state.dispose();
    _postal.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).registerFarmOwner(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            password: _password.text,
            farmName: _farmName.text.trim(),
            addressLine1: _address.text.trim(),
            area: _area.text.trim(),
            city: _city.text.trim(),
            stateName: _state.text.trim(),
            postalCode: _postal.text.trim(),
            businessName: _businessName.text.trim().isEmpty
                ? null
                : _businessName.text.trim(),
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text("${l10n.register}: ${l10n.farm}")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const BrandLogo(variant: BrandLogoVariant.compact, height: 56),
                const SizedBox(height: 8),
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.leafDark,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: l10n.name),
                  validator: LoginValidators.name,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.mobileNumber,
                    prefixText: '+91 ',
                  ),
                  validator: LoginValidators.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.password),
                  validator: LoginValidators.password,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _farmName,
                  decoration: InputDecoration(labelText: l10n.farm),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _businessName,
                  decoration: InputDecoration(
                    labelText: '${l10n.name} (${l10n.optional})',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _address,
                  decoration: InputDecoration(labelText: l10n.address),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _area,
                  decoration: InputDecoration(labelText: l10n.address),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _city,
                  decoration: InputDecoration(labelText: l10n.city),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _state,
                  decoration: InputDecoration(labelText: l10n.state),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _postal,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.postalCode),
                  validator: LoginValidators.postalCode,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(
                    _submitting ? l10n.registering : l10n.createAccount,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
