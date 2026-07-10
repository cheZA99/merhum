import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import '../public/home_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _openChangePassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'Porodica':
        return 'Porodica';
      case 'Imam':
        return 'Imam';
      case 'PogrebnoPreduzeće':
        return 'Pogrebno preduzeće';
      default:
        return role;
    }
  }

  String _initials(String first, String last) {
    String i = '';
    if (first.isNotEmpty) i += first[0];
    if (last.isNotEmpty) i += last[0];
    return i.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline, size: 80, color: AppColors.textLight),
                const SizedBox(height: 16),
                const Text('Niste prijavljeni', style: AppTextStyles.heading2),
                const SizedBox(height: 8),
                const Text('Prijavite se da pristupite svom profilu.', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text('Prijavi se'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                child: Text(
                  _initials(auth.firstName, auth.lastName),
                  style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Text(auth.fullName, style: AppTextStyles.heading1),
              const SizedBox(height: 4),
              Text('@${auth.username}', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_roleLabel(auth.role), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 32),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline, color: AppColors.primary),
                      title: const Text('Korisničko ime'),
                      subtitle: Text(auth.username),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.badge_outlined, color: AppColors.primary),
                      title: const Text('Uloga'),
                      subtitle: Text(_roleLabel(auth.role)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openChangePassword(context),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Promijeni lozinku'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Odjavi se'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await context.read<AuthProvider>().changePassword(
          _currentCtrl.text,
          _newCtrl.text,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (error == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lozinka je uspješno promijenjena.'), backgroundColor: AppColors.success),
      );
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Promijeni lozinku'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Trenutna lozinka'),
              validator: (v) => (v == null || v.isEmpty) ? 'Unesite trenutnu lozinku.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nova lozinka'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Unesite novu lozinku.';
                if (v.length < 4) return 'Lozinka mora imati minimalno 4 karaktera.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Potvrdi novu lozinku'),
              validator: (v) => v != _newCtrl.text ? 'Lozinke se ne podudaraju.' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Odustani'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Sačuvaj'),
        ),
      ],
    );
  }
}
