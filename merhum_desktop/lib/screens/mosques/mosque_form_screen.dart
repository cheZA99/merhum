import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/mosque_model.dart';
import '../../providers/mosque_provider.dart';
import '../../utils/constants.dart';

class MosqueFormScreen extends StatefulWidget {
  final MosqueModel? mosque;

  const MosqueFormScreen({super.key, this.mosque});

  @override
  State<MosqueFormScreen> createState() => _MosqueFormScreenState();
}

class _MosqueFormScreenState extends State<MosqueFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nazivCtrl;
  late final TextEditingController _adresaCtrl;
  late final TextEditingController _telefonCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _kapacitetCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;

  int? _selectedGradId;
  bool _jeAktivan = true;
  bool _isSaving = false;

  bool get _isEdit => widget.mosque != null;

  @override
  void initState() {
    super.initState();
    final m = widget.mosque;
    _nazivCtrl = TextEditingController(text: m?.naziv ?? '');
    _adresaCtrl = TextEditingController(text: m?.adresa ?? '');
    _telefonCtrl = TextEditingController(text: m?.telefon ?? '');
    _emailCtrl = TextEditingController(text: m?.email ?? '');
    _kapacitetCtrl = TextEditingController(
        text: m?.kapacitet != null ? m!.kapacitet.toString() : '');
    _latCtrl = TextEditingController(
        text: m?.latitude != null ? m!.latitude.toString() : '');
    _lngCtrl = TextEditingController(
        text: m?.longitude != null ? m!.longitude.toString() : '');
    _selectedGradId = m?.gradId;
    _jeAktivan = m?.jeAktivan ?? true;
  }

  @override
  void dispose() {
    _nazivCtrl.dispose();
    _adresaCtrl.dispose();
    _telefonCtrl.dispose();
    _emailCtrl.dispose();
    _kapacitetCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'name': _nazivCtrl.text.trim(),
      'address': _adresaCtrl.text.trim(),
      'cityId': _selectedGradId,
      'phone': _telefonCtrl.text.trim().isEmpty ? null : _telefonCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'capacity': _kapacitetCtrl.text.isEmpty ? null : int.tryParse(_kapacitetCtrl.text),
      'latitude': _latCtrl.text.isEmpty ? null : double.tryParse(_latCtrl.text),
      'longitude': _lngCtrl.text.isEmpty ? null : double.tryParse(_lngCtrl.text),
      'isActive': _jeAktivan,
    };

    final provider = context.read<MosqueProvider>();
    final success = _isEdit
        ? await provider.update(widget.mosque!.id, data)
        : await provider.create(data);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      // return result to the parent which shows the SnackBar
      Navigator.of(context).pop(_isEdit ? 'updated' : 'created');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.errorMessage ?? 'Greska pri snimanju.'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradovi = context.watch<MosqueProvider>().gradovi;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Uredi mesdžid' : 'Novi mesdžid'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
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
                  controller: _nazivCtrl,
                  label: 'Naziv',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Naziv je obavezan.';
                    if (v.trim().length < 3) return 'Minimum 3 karaktera.';
                    if (v.trim().length > 200) return 'Maksimum 200 karaktera.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedGradId,
                  decoration: const InputDecoration(
                    labelText: 'Grad',
                    border: OutlineInputBorder(),
                  ),
                  items: gradovi
                      .map((g) => DropdownMenuItem<int>(
                            value: g['id'] as int,
                            child: Text(g['name'] as String? ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGradId = v),
                  validator: (v) => v == null ? 'Grad je obavezan.' : null,
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _adresaCtrl,
                  label: 'Adresa',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Adresa je obavezna.';
                    if (v.trim().length > 300) return 'Maksimum 300 karaktera.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _telefonCtrl,
                  label: 'Telefon',
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (v.trim().length < 9) return 'Minimum 9 karaktera.';
                    if (v.trim().length > 20) return 'Maksimum 20 karaktera.';
                    if (!RegExp(r'^[0-9+]+$').hasMatch(v.trim())) {
                      return 'Dozvoljeni su samo brojevi i +.';
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
                      return 'Unesite ispravan email.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _kapacitetCtrl,
                  label: 'Kapacitet',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final n = int.tryParse(v);
                    if (n == null || n <= 0) return 'Kapacitet mora biti veci od 0.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        controller: _latCtrl,
                        label: 'Latitude',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          if (double.tryParse(v) == null) return 'Neispravan broj.';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _field(
                        controller: _lngCtrl,
                        label: 'Longitude',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          if (double.tryParse(v) == null) return 'Neispravan broj.';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Koordinate mozete pronaci na Google Maps.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Aktivan'),
                  value: _jeAktivan,
                  onChanged: (v) => setState(() => _jeAktivan = v),
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
                          : const Text('Spremi'),
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
