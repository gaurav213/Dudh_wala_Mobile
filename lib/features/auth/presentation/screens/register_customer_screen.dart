import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/branding/brand_logo.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/login_validators.dart';

class RegisterCustomerScreen extends ConsumerStatefulWidget {
  const RegisterCustomerScreen({super.key});

  @override
  ConsumerState<RegisterCustomerScreen> createState() =>
      _RegisterCustomerScreenState();
}

class _RegisterCustomerScreenState
    extends ConsumerState<RegisterCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).registerCustomer(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            password: _password.text,
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
      appBar: AppBar(title: Text("${l10n.register}: ${l10n.customer}")),
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
