import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/deceased_model.dart';
import '../../providers/deceased_provider.dart';
import '../../utils/constants.dart';

class DeceasedFormScreen extends StatefulWidget {
  final DeceasedModel? deceased;

  const DeceasedFormScreen({super.key, this.deceased});

  @override
  State<DeceasedFormScreen> createState() => _DeceasedFormScreenState();
}

class _DeceasedFormScreenState extends State<DeceasedFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _placeOfDeathCtrl;
  late final TextEditingController _contactNameCtrl;
  late final TextEditingController _contactPhoneCtrl;
  late final TextEditingController _contactEmailCtrl;
  late final TextEditingController _photoUrlCtrl;

  DateTime? _dateOfBirth;
  DateTime? _dateOfDeath;
  int? _selectedCityId;
  bool _isSaving = false;

  bool get _isEdit => widget.deceased != null;

  @override
  void initState() {
    super.initState();
    final d = widget.deceased;
    _firstNameCtrl = TextEditingController(text: d?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: d?.lastName ?? '');
    _placeOfDeathCtrl = TextEditingController(text: d?.placeOfDeath ?? '');
    _contactNameCtrl = TextEditingController(text: d?.contactPersonName ?? '');
    _contactPhoneCtrl =
        TextEditingController(text: d?.contactPersonPhone ?? '');
    _contactEmailCtrl =
        TextEditingController(text: d?.contactPersonEmail ?? '');
    _photoUrlCtrl = TextEditingController(text: d?.photoUrl ?? '');
    _dateOfBirth = d?.dateOfBirth;
    _dateOfDeath = d?.dateOfDeath;
    _selectedCityId = d?.cityId;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _placeOfDeathCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _contactEmailCtrl.dispose();
    _photoUrlCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  Future<void> _pickDate({required bool isBirth}) async {
    final initial = isBirth
        ? (_dateOfBirth ?? DateTime(1950))
        : (_dateOfDeath ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;

    setState(() {
      if (isBirth) {
        _dateOfBirth = picked;
      } else {
        _dateOfDeath = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<DeceasedProvider>();

    int statusId;
    if (_isEdit) {
      statusId = widget.deceased!.procedureStatusId;
    } else {
      final firstStatus = provider.statuses.isNotEmpty
          ? provider.statuses.reduce(
              (a, b) => a.order < b.order ? a : b,
            )
          : null;
      statusId = firstStatus?.id ?? 1;
    }

    final data = {
      'firstName': _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      'dateOfBirth': _dateOfBirth!.toIso8601String().split('T')[0],
      'dateOfDeath': _dateOfDeath!.toIso8601String().split('T')[0],
      'placeOfDeath': _placeOfDeathCtrl.text.trim(),
      'photoUrl': _photoUrlCtrl.text.trim().isEmpty
          ? null
          : _photoUrlCtrl.text.trim(),
      'contactPersonName': _contactNameCtrl.text.trim(),
      'contactPersonPhone': _contactPhoneCtrl.text.trim(),
      'contactPersonEmail': _contactEmailCtrl.text.trim().isEmpty
          ? null
          : _contactEmailCtrl.text.trim(),
      'cityId': _selectedCityId,
      'procedureStatusId': statusId,
    };

    final success = _isEdit
        ? await provider.update(widget.deceased!.id, data)
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
    final cities = context.watch<DeceasedProvider>().cities;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Uredi zapis' : 'Registruj preminulog'),
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Lični podaci', style: AppTextStyles.heading2),
                      const Divider(height: 24),
                      _field(
                        controller: _firstNameCtrl,
                        label: 'Ime',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ime je obavezno.';
                          }
                          if (v.trim().length > 100) {
                            return 'Maksimum 100 karaktera.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _field(
                        controller: _lastNameCtrl,
                        label: 'Prezime',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Prezime je obavezno.';
                          }
                          if (v.trim().length > 100) {
                            return 'Maksimum 100 karaktera.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Datum rođenja',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today, size: 18),
                          hintText: _dateOfBirth != null
                              ? _formatDate(_dateOfBirth!)
                              : 'Odaberite datum',
                        ),
                        controller: TextEditingController(
                          text: _dateOfBirth != null
                              ? _formatDate(_dateOfBirth!)
                              : '',
                        ),
                        onTap: () => _pickDate(isBirth: true),
                        validator: (_) => _dateOfBirth == null
                            ? 'Datum rođenja je obavezan.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Datum smrti',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today, size: 18),
                          hintText: _dateOfDeath != null
                              ? _formatDate(_dateOfDeath!)
                              : 'Odaberite datum',
                        ),
                        controller: TextEditingController(
                          text: _dateOfDeath != null
                              ? _formatDate(_dateOfDeath!)
                              : '',
                        ),
                        onTap: () => _pickDate(isBirth: false),
                        validator: (_) {
                          if (_dateOfDeath == null) {
                            return 'Datum smrti je obavezan.';
                          }
                          if (_dateOfBirth != null &&
                              _dateOfDeath!.isBefore(_dateOfBirth!)) {
                            return 'Datum smrti ne može biti prije datuma rođenja.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _field(
                        controller: _placeOfDeathCtrl,
                        label: 'Mjesto smrti',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Mjesto smrti je obavezno.';
                          }
                          if (v.trim().length > 200) {
                            return 'Maksimum 200 karaktera.';
                          }
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
                        onChanged: (v) =>
                            setState(() => _selectedCityId = v),
                        validator: (v) =>
                            v == null ? 'Grad je obavezan.' : null,
                      ),
                      const SizedBox(height: 32),
                      const Text('Kontakt osoba',
                          style: AppTextStyles.heading2),
                      const Divider(height: 24),
                      _field(
                        controller: _contactNameCtrl,
                        label: 'Ime kontakt osobe',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ime kontakt osobe je obavezno.';
                          }
                          if (v.trim().length > 200) {
                            return 'Maksimum 200 karaktera.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _field(
                        controller: _contactPhoneCtrl,
                        label: 'Telefon kontakt osobe',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+]')),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Telefon je obavezan.';
                          }
                          if (v.trim().length < 9 || v.trim().length > 20) {
                            return 'Unesite ispravan broj telefona.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _field(
                        controller: _contactEmailCtrl,
                        label: 'Email kontakt osobe',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                              .hasMatch(v.trim())) {
                            return 'Unesite ispravnu email adresu.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _field(
                        controller: _photoUrlCtrl,
                        label: 'URL fotografije',
                        validator: (_) => null,
                      ),
                      if (_photoUrlCtrl.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Image.network(
                            _photoUrlCtrl.text,
                            height: 80,
                            alignment: Alignment.centerLeft,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () =>
                                Navigator.of(context).pop(null),
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
      onChanged: label == 'URL fotografije'
          ? (_) => setState(() {})
          : null,
    );
  }
}
