import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';

class UserFormScreen extends StatefulWidget {
  final UserModel? user;

  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _selectedRole = 'JavniKorisnik';
  int? _selectedCityId;
  bool _changePassword = false;
  bool _isSaving = false;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    if (u != null) {
      _firstNameCtrl.text = u.firstName;
      _lastNameCtrl.text = u.lastName;
      _emailCtrl.text = u.email;
      _phoneCtrl.text = u.phone ?? '';
      _selectedRole = u.role;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<UserProvider>();
      await p.loadCities();
      if (u != null && u.cityName != null && mounted) {
        final match = p.cities.firstWhere(
          (c) => c['name'] == u.cityName,
          orElse: () => {},
        );
        if (match.isNotEmpty) {
          setState(() => _selectedCityId = match['id'] as int?);
        }
      }
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUsername = context.read<AuthProvider>().username;
    final isSelf = _isEdit && widget.user?.username == currentUsername;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Uredi korisnika' : 'Novi korisnik'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, p, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isEdit) ...[
                    _buildUsernameField(),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(child: _buildFirstNameField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildLastNameField()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildPhoneField(),
                  const SizedBox(height: 16),
                  _buildCityField(p),
                  const SizedBox(height: 16),
                  _buildRoleField(isSelf),
                  const SizedBox(height: 16),
                  _buildPasswordSection(),
                  const SizedBox(height: 24),
                  _buildButtons(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameCtrl,
      decoration: const InputDecoration(
        labelText: 'Korisničko ime *',
        border: OutlineInputBorder(),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Korisničko ime je obavezno';
        if (v.trim().length < 3) return 'Minimum 3 karaktera';
        if (v.trim().length > 50) return 'Maksimum 50 karaktera';
        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
          return 'Dozvoljena su samo slova, brojevi i underscore';
        }
        return null;
      },
    );
  }

  Widget _buildFirstNameField() {
    return TextFormField(
      controller: _firstNameCtrl,
      decoration: const InputDecoration(
        labelText: 'Ime *',
        border: OutlineInputBorder(),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Ime je obavezno';
        if (v.trim().length > 100) return 'Maksimum 100 karaktera';
        return null;
      },
    );
  }

  Widget _buildLastNameField() {
    return TextFormField(
      controller: _lastNameCtrl,
      decoration: const InputDecoration(
        labelText: 'Prezime *',
        border: OutlineInputBorder(),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Prezime je obavezno';
        if (v.trim().length > 100) return 'Maksimum 100 karaktera';
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailCtrl,
      decoration: const InputDecoration(
        labelText: 'Email *',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email je obavezan';
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
          return 'Neispravna email adresa';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneCtrl,
      decoration: const InputDecoration(
        labelText: 'Telefon',
        border: OutlineInputBorder(),
        hintText: '+38761...',
      ),
      keyboardType: TextInputType.phone,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        if (!RegExp(r'^\+?[\d\s\-()]{7,20}$').hasMatch(v.trim())) {
          return 'Neispravni format broja telefona';
        }
        return null;
      },
    );
  }

  Widget _buildCityField(UserProvider p) {
    return DropdownButtonFormField<int?>(
      value: _selectedCityId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Grad',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Odaberite grad (opcionalno)'),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('— Bez grada —')),
        ...p.cities.map((c) => DropdownMenuItem<int?>(
              value: c['id'] as int,
              child: Text(c['name'] as String? ?? ''),
            )),
      ],
      onChanged: (v) => setState(() => _selectedCityId = v),
    );
  }

  Widget _buildRoleField(bool isSelf) {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Uloga *',
        border: const OutlineInputBorder(),
        helperText: isSelf ? 'Ne možete mijenjati vlastitu ulogu' : null,
      ),
      items: const [
        DropdownMenuItem(value: 'Administrator', child: Text('Administrator')),
        DropdownMenuItem(value: 'Porodica', child: Text('Porodica')),
        DropdownMenuItem(value: 'JavniKorisnik', child: Text('Javni korisnik')),
        DropdownMenuItem(value: 'Imam', child: Text('Imam')),
        DropdownMenuItem(value: 'PogrebnoPreduzeće', child: Text('Pogrebno preduzeće')),
      ],
      onChanged: isSelf ? null : (v) => setState(() => _selectedRole = v ?? _selectedRole),
    );
  }

  Widget _buildPasswordSection() {
    if (_isEdit) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            title: const Text('Promijeni lozinku'),
            value: _changePassword,
            onChanged: (v) => setState(() {
              _changePassword = v ?? false;
              if (!_changePassword) _passwordCtrl.clear();
            }),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (_changePassword) ...[
            const SizedBox(height: 8),
            _passwordField(required: true),
          ],
        ],
      );
    }
    return _passwordField(required: true);
  }

  Widget _passwordField({required bool required}) {
    return TextFormField(
      controller: _passwordCtrl,
      decoration: const InputDecoration(
        labelText: 'Lozinka *',
        border: OutlineInputBorder(),
      ),
      obscureText: true,
      validator: (v) {
        if (!required) return null;
        if (v == null || v.isEmpty) return 'Lozinka je obavezna';
        if (v.length < 4) return 'Minimum 4 karaktera';
        return null;
      },
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Spremi'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final p = context.read<UserProvider>();
    bool ok;

    if (_isEdit) {
      final data = <String, dynamic>{
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'cityId': _selectedCityId,
        'role': _selectedRole,
        if (_changePassword && _passwordCtrl.text.isNotEmpty)
          'newPassword': _passwordCtrl.text,
      };
      ok = await p.update(widget.user!.id, data);
    } else {
      final data = <String, dynamic>{
        'username': _usernameCtrl.text.trim(),
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'cityId': _selectedCityId,
        'role': _selectedRole,
        'password': _passwordCtrl.text,
      };
      ok = await p.create(data);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Korisnik ažuriran.' : 'Korisnik uspješno dodan.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(p.errorMessage ?? 'Greška. Pokušajte ponovo.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
