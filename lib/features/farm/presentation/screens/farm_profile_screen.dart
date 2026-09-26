import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/widgets/dk_empty.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/farm_models.dart';
import '../providers/farm_providers.dart';

class FarmProfileScreen extends ConsumerStatefulWidget {
  const FarmProfileScreen({super.key});

  @override
  ConsumerState<FarmProfileScreen> createState() => _FarmProfileScreenState();
}

class _FarmProfileScreenState extends ConsumerState<FarmProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _businessName = TextEditingController();
  final _description = TextEditingController();
  final _email = TextEditingController();
  final _addressLine1 = TextEditingController();
  final _addressLine2 = TextEditingController();
  final _area = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postalCode = TextEditingController();

  bool _editing = false;
  bool _saving = false;
  bool _photoBusy = false;
  String? _loadedFarmId;
  List<String> _spokenLanguages = [];

  static const _languageOptions = <(String, String)>[
    ('mr', 'Marathi'),
    ('hi', 'Hindi'),
    ('en', 'English'),
    ('gu', 'Gujarati'),
    ('kn', 'Kannada'),
    ('ta', 'Tamil'),
  ];

  void _populate(FarmModel farm) {
    if (_loadedFarmId == farm.id) return;
    _loadedFarmId = farm.id;
    _name.text = farm.name;
    _businessName.text = farm.businessName ?? '';
    _description.text = farm.description ?? '';
    _email.text = farm.email ?? '';
    _addressLine1.text = farm.addressLine1;
    _addressLine2.text = farm.addressLine2 ?? '';
    _area.text = farm.area;
    _city.text = farm.city;
    _state.text = farm.state;
    _postalCode.text = farm.postalCode;
    _spokenLanguages = List<String>.from(farm.spokenLanguages);
  }

  @override
  void dispose() {
    _name.dispose();
    _businessName.dispose();
    _description.dispose();
    _email.dispose();
    _addressLine1.dispose();
    _addressLine2.dispose();
    _area.dispose();
    _city.dispose();
    _state.dispose();
    _postalCode.dispose();
    super.dispose();
  }

  Future<void> _save(String farmId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(farmApiProvider).updateFarm(farmId, {
        'name': _name.text.trim(),
        'businessName': _businessName.text.trim(),
        'description': _description.text.trim(),
        'email': _email.text.trim(),
        'addressLine1': _addressLine1.text.trim(),
        'addressLine2': _addressLine2.text.trim(),
        'area': _area.text.trim(),
        'city': _city.text.trim(),
        'state': _state.text.trim(),
        'postalCode': _postalCode.text.trim(),
        'spokenLanguages': _spokenLanguages,
      });
      _loadedFarmId = null;
      ref.invalidate(farmDetailProvider);
      invalidateFarmDashboard(ref);
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).farmProfileUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final farmAsync = ref.watch(farmDetailProvider);

    return farmAsync.when(
      data: (farm) {
        _populate(farm);
        return _editing ? _buildForm(farm) : _buildView(farm);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ListView(
        children: [
          const SizedBox(height: 80),
          DkEmpty(
            message: '${AppLocalizations.of(context).couldNotLoad}.\n$e',
            actionLabel: l10n.retry,
            onAction: () => ref.invalidate(farmDetailProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildView(FarmModel farm) {
    final l10n = AppLocalizations.of(context);
    final mediaAsync = ref.watch(farmMediaProvider(farm.id));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          AppLocalizations.of(context).photos,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Dk.of(context).ink,
              ),
        ),
        const SizedBox(height: 8),
        mediaAsync.when(
          data: (photos) => SizedBox(
            height: 112,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final p in photos)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            mediaUrl(p.url) ?? p.url,
                            width: 112,
                            height: 112,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 112,
                              height: 112,
                              color: Dk.of(context).foam,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _deletePhoto(farm.id, p.id),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (photos.length < 5)
                  InkWell(
                    onTap: _photoBusy ? null : () => _addPhoto(farm.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: Dk.of(context).foam,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Dk.of(context).muted.withValues(alpha: 0.3),
                        ),
                      ),
                      child: _photoBusy
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined,
                                    color: AppColors.leaf),
                                const SizedBox(height: 4),
                                Text(
                                  photos.isEmpty
                                      ? AppLocalizations.of(context).addPhoto
                                      : '${photos.length}/5',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Dk.of(context).muted,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
              ],
            ),
          ),
          loading: () => const SizedBox(
            height: 112,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Text(
            AppLocalizations.of(context).couldNotLoad,
            style: TextStyle(color: Dk.of(context).muted),
          ),
        ),
        const SizedBox(height: 20),
        _InfoTile(label: l10n.name, value: farm.name),
        _InfoTile(label: AppLocalizations.of(context).businessName, value: farm.businessName ?? '—'),
        _InfoTile(label: AppLocalizations.of(context).description, value: farm.description ?? '—'),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).spokenLanguages,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Dk.of(context).ink,
              ),
        ),
        const SizedBox(height: 8),
        _LanguageChips(
          selected: _spokenLanguages,
          options: _languageOptions,
          onToggle: _toggleLanguage,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonal(
            onPressed: _saving ? null : () => _saveLanguages(farm.id),
            child: Text(_saving ? l10n.saving : AppLocalizations.of(context).saveLanguages),
          ),
        ),
        const SizedBox(height: 12),
        _InfoTile(label: l10n.emailOptional, value: farm.email ?? '—'),
        _InfoTile(
          label: l10n.address,
          value: [
            farm.addressLine1,
            if ((farm.addressLine2 ?? '').isNotEmpty) farm.addressLine2!,
            farm.area,
            farm.city,
            farm.state,
            farm.postalCode,
          ].join(', '),
        ),
        _InfoTile(label: l10n.status, value: farm.status.replaceAll('_', ' ')),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => setState(() => _editing = true),
          icon: const Icon(Icons.edit_outlined),
          label: Text(l10n.editProfile),
        ),
      ],
    );
  }

  Future<void> _saveLanguages(String farmId) async {
    setState(() => _saving = true);
    try {
      await ref.read(farmApiProvider).updateFarm(farmId, {
        'spokenLanguages': _spokenLanguages,
      });
      _loadedFarmId = null;
      ref.invalidate(farmDetailProvider);
      invalidateFarmDashboard(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).languagesUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleLanguage(String code) {
    if (_spokenLanguages.contains(code)) {
      setState(() {
        _spokenLanguages = _spokenLanguages.where((c) => c != code).toList();
      });
      return;
    }
    if (_spokenLanguages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).maxFiveLanguages)),
      );
      return;
    }
    setState(() => _spokenLanguages = [..._spokenLanguages, code]);
  }

  Future<void> _addPhoto(String farmId) async {
    if (_photoBusy) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return;
    setState(() => _photoBusy = true);
    try {
      await ref.read(farmApiProvider).uploadMedia(farmId, picked.path);
      ref.invalidate(farmMediaProvider(farmId));
      try {
        await ref.read(farmMediaProvider(farmId).future);
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _deletePhoto(String farmId, String mediaId) async {
    if (_photoBusy) return;
    setState(() => _photoBusy = true);
    try {
      await ref.read(farmApiProvider).deleteMedia(farmId, mediaId);
      ref.invalidate(farmMediaProvider(farmId));
      try {
        await ref.read(farmMediaProvider(farmId).future);
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Widget _buildForm(FarmModel farm) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _name,
            decoration: InputDecoration(labelText: AppLocalizations.of(context).farmName),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _businessName,
            decoration: InputDecoration(labelText: AppLocalizations.of(context).businessName),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _description,
            decoration: InputDecoration(labelText: AppLocalizations.of(context).description),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).spokenLanguages,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          _LanguageChips(
            selected: _spokenLanguages,
            options: _languageOptions,
            onToggle: _toggleLanguage,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            decoration: InputDecoration(labelText: l10n.emailOptional),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressLine1,
            decoration: InputDecoration(labelText: AppLocalizations.of(context).addressLine1),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressLine2,
            decoration: InputDecoration(labelText: AppLocalizations.of(context).addressLine2),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _area,
            decoration: InputDecoration(labelText: AppLocalizations.of(context).area),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _city,
            decoration: InputDecoration(labelText: l10n.city),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _state,
            decoration: InputDecoration(labelText: l10n.state),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _postalCode,
            decoration: InputDecoration(labelText: l10n.postalCode),
            keyboardType: TextInputType.number,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                            _editing = false;
                            _spokenLanguages =
                                List<String>.from(farm.spokenLanguages);
                          }),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : () => _save(farm.id),
                  child: Text(_saving ? l10n.saving : l10n.save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Dk.of(context).milkWhite,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: Dk.of(context).muted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value),
          ],
        ),
      ),
    );
  }
}

class _LanguageChips extends StatelessWidget {
  const _LanguageChips({
    required this.selected,
    required this.options,
    required this.onToggle,
  });

  final List<String> selected;
  final List<(String, String)> options;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (code, label) in options)
          FilterChip(
            label: Text(label),
            selected: selected.contains(code),
            onSelected: (_) => onToggle(code),
          ),
      ],
    );
  }
}
