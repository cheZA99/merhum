import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/cemetery_model.dart';
import '../../providers/cemetery_provider.dart';
import '../../utils/constants.dart';

class CemeteryFormScreen extends StatefulWidget {
  final CemeteryModel? cemetery;
  const CemeteryFormScreen({super.key, this.cemetery});

  @override
  State<CemeteryFormScreen> createState() => _CemeteryFormScreenState();
}

class _CemeteryFormScreenState extends State<CemeteryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _totalCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  int? _selectedCityId;
  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEdit => widget.cemetery != null;

  @override
  void initState() {
    super.initState();
    final g = widget.cemetery;
    _nameCtrl = TextEditingController(text: g?.name ?? '');
    _addressCtrl = TextEditingController(text: g?.address ?? '');
    _totalCtrl = TextEditingController(
        text: g?.totalPlots != null && g!.totalPlots > 0
            ? g.totalPlots.toString()
            : '');
    _latCtrl = TextEditingController(
        text: g?.latitude != null ? g!.latitude.toString() : '');
    _lngCtrl = TextEditingController(
        text: g?.longitude != null ? g!.longitude.toString() : '');
    _selectedCityId = g?.cityId != 0 ? g?.cityId : null;
    _isActive = g?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _totalCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'cityId': _selectedCityId,
      'totalPlaces': int.parse(_totalCtrl.text),
      'latitude': _latCtrl.text.isEmpty ? null : double.tryParse(_latCtrl.text),
      'longitude': _lngCtrl.text.isEmpty ? null : double.tryParse(_lngCtrl.text),
      'isActive': _isActive,
    };

    final provider = context.read<CemeteryProvider>();
    final success = _isEdit
        ? await provider.update(widget.cemetery!.id, data)
        : await provider.create(data);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop(_isEdit ? 'updated' : 'created');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.errorMessage ?? 'Error saving.'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cities = context.watch<CemeteryProvider>().cities;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Uredi groblje' : 'Novo groblje'),
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
                      labelText: 'Grad', border: OutlineInputBorder()),
                  items: cities
                      .map((g) => DropdownMenuItem<int>(
                            value: g['id'] as int,
                            child: Text(g['name'] as String? ?? ''),
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
                  controller: _totalCtrl,
                  label: 'Ukupno mjesta',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ukupno mjesta je obavezno.';
                    final n = int.tryParse(v);
                    if (n == null || n <= 0) return 'Mora biti veće od 0.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        controller: _latCtrl,
                        label: 'Geografska širina',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                        label: 'Geografska dužina',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                const Text('Unesite GPS koordinate groblja.',
                    style: AppTextStyles.caption),
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
                                  strokeWidth: 2, color: Colors.white))
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
          labelText: label, border: const OutlineInputBorder()),
      validator: validator,
    );
  }
}
