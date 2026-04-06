import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/imam_model.dart';
import '../../providers/imam_provider.dart';
import '../../utils/constants.dart';

class ImamFormScreen extends StatefulWidget {
  final ImamModel? imam;

  const ImamFormScreen({super.key, this.imam});

  @override
  State<ImamFormScreen> createState() => _ImamFormScreenState();
}

class _ImamFormScreenState extends State<ImamFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;

  int? _selectedMosqueId;
  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEdit => widget.imam != null;

  @override
  void initState() {
    super.initState();
    final m = widget.imam;
    _firstNameCtrl = TextEditingController(text: m?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: m?.lastName ?? '');
    _phoneCtrl = TextEditingController(text: m?.phone ?? '');
    _emailCtrl = TextEditingController(text: m?.email ?? '');
    _selectedMosqueId = m?.mosqueId;
    _isActive = m?.isActive ?? true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImamProvider>().loadMosques();
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'firstName': _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      'mosqueId': _selectedMosqueId,
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'isActive': _isActive,
    };

    final provider = context.read<ImamProvider>();
    final success = _isEdit
        ? await provider.update(widget.imam!.id, data)
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
    final mosques = context.watch<ImamProvider>().mosques;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Uredi imama' : 'Novi imam'),
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
                  controller: _firstNameCtrl,
                  label: 'Ime',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ime je obavezno.';
                    if (v.trim().length > 100) return 'Maksimum 100 karaktera.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _lastNameCtrl,
                  label: 'Prezime',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Prezime je obavezno.';
                    if (v.trim().length > 100) return 'Maksimum 100 karaktera.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedMosqueId,
                  decoration: const InputDecoration(
                    labelText: 'Mesdžid',
                    border: OutlineInputBorder(),
                  ),
                  items: mosques
                      .map((m) => DropdownMenuItem<int>(
                            value: m['id'] as int,
                            child: Text(m['name'] as String? ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedMosqueId = v),
                  validator: (v) => v == null ? 'Mesdžid je obavezan.' : null,
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
