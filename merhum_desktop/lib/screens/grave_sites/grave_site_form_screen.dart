import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/grave_site_model.dart';
import '../../providers/cemetery_provider.dart';
import '../../providers/grave_site_provider.dart';
import '../../utils/constants.dart';
import '../../utils/status_helper.dart';

class GraveSiteFormScreen extends StatefulWidget {
  final GraveSiteModel? site;
  final int? initialCemeteryId;

  const GraveSiteFormScreen({
    super.key,
    this.site,
    this.initialCemeteryId,
  });

  @override
  State<GraveSiteFormScreen> createState() =>
      _GraveSiteFormScreenState();
}

class _GraveSiteFormScreenState extends State<GraveSiteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberCtrl;
  late final TextEditingController _rowCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;

  int? _selectedCemeteryId;
  int? _selectedSectorId;
  int? _selectedDeceasedId;
  late String _status;
  late String _originalStatus;
  bool _isSaving = false;
  bool _deceasedChanged = false;

  bool get _isEdit => widget.site != null;

  @override
  void initState() {
    super.initState();
    final m = widget.site;
    _numberCtrl = TextEditingController(text: m?.plotNumber ?? '');
    _rowCtrl = TextEditingController(text: m?.row?.toString() ?? '');
    _latCtrl = TextEditingController(text: m?.latitude?.toString() ?? '');
    _lngCtrl = TextEditingController(text: m?.longitude?.toString() ?? '');
    _selectedCemeteryId = m?.cemeteryId ?? widget.initialCemeteryId;
    _selectedSectorId = m?.sectorId;
    _selectedDeceasedId = m?.deceasedId;
    _status = m?.status ?? GraveSiteStatus.available;
    _originalStatus = _status;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GraveSiteProvider>();
      // In edit mode pass the current deceased so they appear in the dropdown even if already assigned
      provider.loadDeceased(currentDeceasedId: widget.site?.deceasedId);
      if (_selectedCemeteryId != null) {
        provider.loadSectors(_selectedCemeteryId!);
      }
    });
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _rowCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final data = {
      'cemeteryId': _selectedCemeteryId,
      'sectionId': _selectedSectorId,
      'plotNumber': _numberCtrl.text.trim(),
      'row': _rowCtrl.text.isEmpty ? null : int.tryParse(_rowCtrl.text),
      'latitude':
          _latCtrl.text.isEmpty ? null : double.tryParse(_latCtrl.text),
      'longitude':
          _lngCtrl.text.isEmpty ? null : double.tryParse(_lngCtrl.text),
    };

    final provider = context.read<GraveSiteProvider>();
    bool success;

    try {
      if (_isEdit) {
        success = await provider.update(
          widget.site!.id,
          data,
          deceasedId: _selectedDeceasedId,
          assignChanged: _deceasedChanged && _selectedDeceasedId != null,
          newStatus: _status,
          oldStatus: _originalStatus,
        );
      } else {
        success = await provider.create(
          data,
          deceasedId: _selectedDeceasedId,
          status: _status,
        );
      }
    } catch (e) {
      success = false;
      provider.errorMessage = 'Unexpected error: $e';
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop(_isEdit ? 'updated' : 'created');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.errorMessage ?? 'Error saving.'),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 5),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cemeteries = context.watch<CemeteryProvider>().cemeteries;
    final provider = context.watch<GraveSiteProvider>();
    final sectorList = provider.sectors;
    final deceasedList = provider.deceased;
    final cemeteryFixed = widget.initialCemeteryId != null || _isEdit;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(_isEdit ? 'Uredi mezarsko mjesto' : 'Novo mezarsko mjesto'),
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
                DropdownButtonFormField<int>(
                  value: _selectedCemeteryId,
                  decoration: const InputDecoration(
                      labelText: 'Groblje', border: OutlineInputBorder()),
                  items: cemeteries
                      .map((g) => DropdownMenuItem<int>(
                            value: g.id,
                            child: Text(g.name),
                          ))
                      .toList(),
                  onChanged: cemeteryFixed
                      ? null
                      : (v) {
                          setState(() {
                            _selectedCemeteryId = v;
                            _selectedSectorId = null;
                          });
                          if (v != null) provider.loadSectors(v);
                        },
                  validator: (v) => v == null ? 'Groblje je obavezno.' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  value: _selectedSectorId,
                  decoration: const InputDecoration(
                      labelText: 'Sektor (opcionalno)',
                      border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<int?>(
                        value: null, child: Text('— Bez sektora —')),
                    ...sectorList.map((s) => DropdownMenuItem<int?>(
                          value: s['id'] as int?,
                          child: Text(s['name'] as String? ?? ''),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedSectorId = v),
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _numberCtrl,
                  label: 'Broj mjesta (npr. A-123)',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Broj mjesta je obavezno.'
                      : null,
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _rowCtrl,
                  label: 'Red (opcionalno)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                      labelText: 'Status', border: OutlineInputBorder()),
                  items: GraveSiteStatus.apiValues
                      .map((apiVal) => DropdownMenuItem(
                            value: apiVal,
                            child: Text(GraveSiteStatus.display(apiVal)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _status = v ?? GraveSiteStatus.available;
                    if (_status != GraveSiteStatus.occupied) {
                      _selectedDeceasedId = null;
                      _deceasedChanged = true;
                    }
                  }),
                ),
                const SizedBox(height: 16),
                if (_status == GraveSiteStatus.occupied) ...[
                  DropdownButtonFormField<int?>(
                    value: _selectedDeceasedId,
                    decoration: const InputDecoration(
                        labelText: 'Preminuli',
                        border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('— Odaberite preminulog —')),
                      ...deceasedList.map((p) {
                        final id = p['id'] as int?;
                        final firstName = p['firstName'] as String? ?? '';
                        final lastName = p['lastName'] as String? ?? '';
                        return DropdownMenuItem<int?>(
                          value: id,
                          child: Text('$firstName $lastName'.trim()),
                        );
                      }),
                    ],
                    onChanged: (v) => setState(() {
                      _selectedDeceasedId = v;
                      _deceasedChanged = true;
                      if (v != null) _status = GraveSiteStatus.occupied;
                    }),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        controller: _latCtrl,
                        label: 'Geografska širina',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          if (double.tryParse(v) == null) {
                            return 'Neispravan broj.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _field(
                        controller: _lngCtrl,
                        label: 'Geografska dužina',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          if (double.tryParse(v) == null) {
                            return 'Neispravan broj.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Nakon čuvanja, automatski se generiše QR kod za nadgrobnu ploču.',
                  style: AppTextStyles.caption,
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
