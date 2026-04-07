import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/funeral_home_model.dart';
import '../../providers/funeral_home_provider.dart';
import '../../utils/constants.dart';

class FuneralHomeFormScreen extends StatefulWidget {
  final FuneralHomeModel? home;

  const FuneralHomeFormScreen({super.key, this.home});

  @override
  State<FuneralHomeFormScreen> createState() => _FuneralHomeFormScreenState();
}

class _FuneralHomeFormScreenState extends State<FuneralHomeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _licenseCtrl;

  int? _selectedCityId;
  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEdit => widget.home != null;

  @override
  void initState() {
    super.initState();
    final h = widget.home;
    _nameCtrl = TextEditingController(text: h?.name ?? '');
    _addressCtrl = TextEditingController(text: h?.address ?? '');
    _phoneCtrl = TextEditingController(text: h?.phone ?? '');
    _emailCtrl = TextEditingController(text: h?.email ?? '');
    _licenseCtrl = TextEditingController(text: h?.licenseNumber ?? '');
    _selectedCityId = h?.cityId;
    _isActive = h?.isActive ?? true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FuneralHomeProvider>().loadCities();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'cityId': _selectedCityId,
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'licenseNumber': _licenseCtrl.text.trim().isEmpty
          ? null
          : _licenseCtrl.text.trim(),
      'isActive': _isActive,
    };

    final provider = context.read<FuneralHomeProvider>();
    final success = _isEdit
        ? await provider.update(widget.home!.id, data)
        : await provider.create(data);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop(_isEdit ? 'updated' : 'created');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.errorMessage ?? 'Greška pri snimanju.'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cities = context.watch<FuneralHomeProvider>().cities;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit
            ? 'Uredi pogrebno preduzeće'
            : 'Novo pogrebno preduzeće'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(null),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(
                  controller: _nameCtrl,
                  label: 'Naziv',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Naziv je obavezan.';
                    if (v.trim().length > 200) return 'Maksimum 200 karaktera.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedCityId,
                  decoration: const InputDecoration(
                    labelText: 'Grad',
                    border: OutlineInputBorder(),
                  ),
                  items: cities
                      .map((c) => DropdownMenuItem<int>(
                            value: c['id'] as int,
                            child: Text(c['name'] as String? ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCityId = v),
                  validator: (v) => v == null ? 'Grad je obavezan.' : null,
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _addressCtrl,
                  label: 'Adresa',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Adresa je obavezna.';
                    if (v.trim().length > 300) return 'Maksimum 300 karaktera.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _phoneCtrl,
                  label: 'Telefon',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Telefon je obavezan.';
                    if (v.trim().length < 9 || v.trim().length > 20) {
                      return 'Unesite ispravan broj telefona.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _emailCtrl,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                      return 'Unesite ispravnu email adresu.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _licenseCtrl,
                  label: 'Licencni broj',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (v.trim().length > 100) return 'Maksimum 100 karaktera.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Aktivan'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Odustani'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isSaving ? null : _submit,
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sačuvaj'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
