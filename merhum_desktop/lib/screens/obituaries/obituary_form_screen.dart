import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/obituary_provider.dart';
import '../../utils/constants.dart';

class ObituaryFormScreen extends StatefulWidget {
  final int? preselectedDeceasedId;

  const ObituaryFormScreen({super.key, this.preselectedDeceasedId});

  @override
  State<ObituaryFormScreen> createState() => _ObituaryFormScreenState();
}

class _ObituaryFormScreenState extends State<ObituaryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedDeceasedId;
  bool _isPublic = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDeceasedId = widget.preselectedDeceasedId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObituaryProvider>().loadDeceasedDropdown();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova smrtovnica'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Consumer<ObituaryProvider>(
        builder: (context, p, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<int>(
                    value: _selectedDeceasedId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Preminuli *',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Odaberite preminulog'),
                    items: p.deceased.map((d) {
                      return DropdownMenuItem<int>(
                        value: d['id'] as int,
                        child: Text('${d['firstName']} ${d['lastName']}'),
                      );
                    }).toList(),
                    onChanged: widget.preselectedDeceasedId != null
                        ? null
                        : (v) => setState(() => _selectedDeceasedId = v),
                    validator: (v) => v == null ? 'Odaberite preminulog' : null,
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text('Javna smrtovnica'),
                    subtitle: const Text('Vidljiva svima bez prijave'),
                    value: _isPublic,
                    onChanged: (v) => setState(() => _isPublic = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  Row(
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
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Kreiraj'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final ok = await context
        .read<ObituaryProvider>()
        .create(_selectedDeceasedId!, _isPublic);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Smrtovnica uspješno kreirana.'),
            backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              context.read<ObituaryProvider>().errorMessage ?? 'Greška. Pokušajte ponovo.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
