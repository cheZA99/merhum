import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/deceased_provider.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';

class RegisterDeceasedScreen extends StatefulWidget {
  const RegisterDeceasedScreen({super.key});

  @override
  State<RegisterDeceasedScreen> createState() => _RegisterDeceasedScreenState();
}

class _RegisterDeceasedScreenState extends State<RegisterDeceasedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _placeOfDeathCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();

  DateTime? _dateOfBirth;
  DateTime? _dateOfDeath;
  int? _cityId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeceasedProvider>().loadCities();
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _placeOfDeathCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _contactEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isBirth) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isBirth ? DateTime(now.year - 60) : now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        if (isBirth) {
          _dateOfBirth = picked;
        } else {
          _dateOfDeath = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfDeath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Odaberite datum smrti'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _submitting = true);
    final body = {
      'firstName': _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      if (_dateOfBirth != null) 'dateOfBirth': _dateOfBirth!.toIso8601String(),
      'dateOfDeath': _dateOfDeath!.toIso8601String(),
      'placeOfDeath': _placeOfDeathCtrl.text.trim(),
      if (_cityId != null) 'cityId': _cityId,
      'contactPerson': _contactNameCtrl.text.trim(),
      'contactPhone': _contactPhoneCtrl.text.trim(),
      'contactEmail': _contactEmailCtrl.text.trim(),
      'procedureStatusId': 1,
    };
    final result = await context.read<DeceasedProvider>().create(body);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preminuli uspješno prijavljen'), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Greška pri prijavi'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cities = context.watch<DeceasedProvider>().cities;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Prijavi preminulog')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _firstNameCtrl,
                  decoration: const InputDecoration(labelText: 'Ime'),
                  validator: (v) => v?.isEmpty == true ? 'Obavezno polje' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameCtrl,
                  decoration: const InputDecoration(labelText: 'Prezime'),
                  validator: (v) => v?.isEmpty == true ? 'Obavezno polje' : null,
                ),
                const SizedBox(height: 12),
                _DateField(
                  label: 'Datum rođenja',
                  value: _dateOfBirth,
                  onTap: () => _pickDate(true),
                ),
                const SizedBox(height: 12),
                _DateField(
                  label: 'Datum smrti',
                  value: _dateOfDeath,
                  onTap: () => _pickDate(false),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _placeOfDeathCtrl,
                  decoration: const InputDecoration(labelText: 'Mjesto smrti'),
                  validator: (v) => v?.isEmpty == true ? 'Obavezno polje' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _cityId,
                  decoration: const InputDecoration(labelText: 'Grad'),
                  items: cities.map((c) => DropdownMenuItem<int>(
                    value: c['id'] as int,
                    child: Text(c['name'] as String? ?? ''),
                  )).toList(),
                  onChanged: (v) => setState(() => _cityId = v),
                  validator: (v) => v == null ? 'Obavezno polje' : null,
                ),
                const SizedBox(height: 24),
                const Text('Kontakt osoba', style: AppTextStyles.heading3),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactNameCtrl,
                  decoration: const InputDecoration(labelText: 'Ime i prezime'),
                  validator: (v) => v?.isEmpty == true ? 'Obavezno polje' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefon'),
                  validator: (v) => v?.isEmpty == true ? 'Obavezno polje' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Prijavi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today_outlined)),
        child: Text(
          value == null ? 'Odaberi datum' : DateFormatter.date(value),
          style: value == null ? AppTextStyles.bodyMedium : AppTextStyles.body,
        ),
      ),
    );
  }
}
