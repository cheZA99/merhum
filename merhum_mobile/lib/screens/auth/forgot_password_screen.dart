import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/api_error.dart';
import '../../utils/constants.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await AuthService.forgotPassword(_emailCtrl.text.trim());
      if (!mounted) return;
      setState(() => _codeSent = true);
      _snack('Ako nalog postoji, kod je poslan na email.', AppColors.success);
    } catch (e) {
      if (!mounted) return;
      _snack(parseApiError(e), AppColors.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (!_resetFormKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await AuthService.resetPassword(
        _emailCtrl.text.trim(),
        _tokenCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (!mounted) return;
      _snack('Lozinka je promijenjena. Možete se prijaviti.', AppColors.success);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _snack(parseApiError(e), AppColors.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Zaboravljena lozinka')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                key: _emailFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Unesite email adresu vašeg naloga. Poslat ćemo kod za postavljanje nove lozinke.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      enabled: !_codeSent,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Unesite email';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                          return 'Email nije ispravan';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (!_codeSent)
                      ElevatedButton(
                        onPressed: _busy ? null : _sendCode,
                        child: _busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Pošalji kod'),
                      ),
                  ],
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Form(
                  key: _resetFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _tokenCtrl,
                        decoration: const InputDecoration(labelText: 'Kod iz emaila'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Unesite kod' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Nova lozinka'),
                        validator: (v) =>
                            (v == null || v.length < 4) ? 'Lozinka mora imati najmanje 4 znaka' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Potvrdi lozinku'),
                        validator: (v) => v != _passwordCtrl.text ? 'Lozinke se ne podudaraju' : null,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _busy ? null : _reset,
                        child: _busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Postavi novu lozinku'),
                      ),
                      TextButton(
                        onPressed: _busy ? null : _sendCode,
                        child: const Text('Pošalji kod ponovo'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
