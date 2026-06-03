import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/deceased_model.dart';
import '../../models/obituary_model.dart';
import '../../providers/deceased_provider.dart';
import '../../services/obituary_service.dart';
import '../../utils/constants.dart';
import 'share_obituary_screen.dart';

class CreateObituaryScreen extends StatefulWidget {
  const CreateObituaryScreen({super.key});

  @override
  State<CreateObituaryScreen> createState() => _CreateObituaryScreenState();
}

class _CreateObituaryScreenState extends State<CreateObituaryScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _deceasedId;
  bool _isPublic = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeceasedProvider>().loadMyDeceased();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final ObituaryModel obituary = await ObituaryService.createObituary(_deceasedId!, _isPublic);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Smrtovnica kreirana'), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ShareObituaryScreen(obituary: obituary)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška: ${e.toString()}'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<DeceasedModel> list = context.watch<DeceasedProvider>().myDeceased;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kreiraj smrtovnicu')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  value: _deceasedId,
                  decoration: const InputDecoration(labelText: 'Preminuli'),
                  items: list.map((d) => DropdownMenuItem<int>(
                    value: d.id,
                    child: Text(d.fullName),
                  )).toList(),
                  onChanged: (v) => setState(() => _deceasedId = v),
                  validator: (v) => v == null ? 'Obavezno polje' : null,
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    value: _isPublic,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _isPublic = v),
                    title: const Text('Javna smrtovnica', style: AppTextStyles.heading3),
                    subtitle: const Text('Vidljiva svima putem javne pretrage', style: AppTextStyles.caption),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Kreiraj smrtovnicu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
