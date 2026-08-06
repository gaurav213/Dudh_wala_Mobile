import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/login_validators.dart';
import '../providers/customer_providers.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.customerId});

  final String? customerId;

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _rate = TextEditingController(text: '60');
  final _notes = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) {
      Future.microtask(_load);
    }
  }

  Future<void> _load() async {
    final c = await ref.read(customerRepositoryProvider).get(widget.customerId!);
    if (c == null || !mounted) return;
    _name.text = c['name'] as String;
    _phone.text = c['phone'] as String;
    _address.text = (c['address'] as String?) ?? '';
    _rate.text = '${c['default_rate_per_litre']}';
    _notes.text = (c['notes'] as String?) ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _rate.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final rate = double.tryParse(_rate.text.trim()) ?? 0;
      final repo = ref.read(customerRepositoryProvider);
      if (widget.customerId == null) {
        await repo.create(
          supplierId: user.id,
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          defaultRatePerLitre: rate,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
      } else {
        await repo.update(widget.customerId!, {
          'name': _name.text.trim(),
          'phone': _phone.text.trim(),
          'address': _address.text.trim(),
          'default_rate_per_litre': rate,
          'notes': _notes.text.trim(),
        });
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.customerId != null;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(editing ? 'Edit customer' : 'Add customer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: LoginValidators.name,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixText: '+91 ',
              ),
              validator: LoginValidators.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rate,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Default rate / litre (₹)',
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n < 0) return 'Enter a valid rate';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: Text(_loading ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
