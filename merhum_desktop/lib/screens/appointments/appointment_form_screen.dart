import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../utils/constants.dart';

class AppointmentFormScreen extends StatefulWidget {
  final AppointmentModel? appointment;
  final int? preselectedDeceasedId;

  const AppointmentFormScreen({
    super.key,
    this.appointment,
    this.preselectedDeceasedId,
  });

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedDeceasedId;
  int? _selectedMosqueId;
  int? _selectedImamId;
  int? _selectedCemeteryId;
  int? _selectedGraveSiteId;
  String _selectedStatus = 'Scheduled';
  DateTime? _funeralDateTime;
  final _noteCtrl = TextEditingController();

  List<Map<String, dynamic>> _imams = [];
  List<Map<String, dynamic>> _graveSites = [];
  bool _isSaving = false;
  bool _mosqueLoading = false;
  bool _cemeteryLoading = false;

  bool get _isEdit => widget.appointment != null;

  @override
  void initState() {
    super.initState();
    final a = widget.appointment;
    if (a != null) {
      _selectedDeceasedId = a.deceasedId;
      _selectedMosqueId = a.mosqueId;
      _selectedImamId = a.imamId;
      _selectedCemeteryId = a.cemeteryId;
      _selectedGraveSiteId = a.graveSiteId;
      _selectedStatus = a.status;
      _funeralDateTime = a.funeralDateTime.toLocal();
      _noteCtrl.text = a.note ?? '';
    } else if (widget.preselectedDeceasedId != null) {
      _selectedDeceasedId = widget.preselectedDeceasedId;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<AppointmentProvider>();
      await p.loadDropdownData();

      if (_selectedMosqueId != null) {
        final imams = await p.loadImamsForMosque(_selectedMosqueId!);
        if (mounted) setState(() => _imams = imams);
      }
      if (_selectedCemeteryId != null) {
        final sites = await p.loadGraveSitesForCemetery(_selectedCemeteryId!);
        if (mounted) setState(() => _graveSites = sites);
      }
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Uredi termin' : 'Zakažite termin'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Consumer<AppointmentProvider>(
        builder: (context, p, _) {
          if (p.isLoading && p.mosques.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeceasedField(p),
                  const SizedBox(height: 16),
                  _buildMosqueField(p),
                  const SizedBox(height: 16),
                  _buildImamField(),
                  const SizedBox(height: 16),
                  _buildDateTimeField(),
                  const SizedBox(height: 16),
                  _buildCemeteryField(p),
                  const SizedBox(height: 16),
                  _buildGraveSiteField(),
                  const SizedBox(height: 16),
                  _buildStatusField(),
                  const SizedBox(height: 16),
                  _buildNoteField(),
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

  Widget _buildDeceasedField(AppointmentProvider p) {
    final isLocked = widget.preselectedDeceasedId != null && !_isEdit;
    return DropdownButtonFormField<int>(
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
      onChanged: isLocked ? null : (v) => setState(() => _selectedDeceasedId = v),
      validator: (v) => v == null ? 'Odaberite preminulog' : null,
    );
  }

  Widget _buildMosqueField(AppointmentProvider p) {
    return DropdownButtonFormField<int>(
      value: _selectedMosqueId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Džamija *',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Odaberite džamiju'),
      items: p.mosques.map((m) {
        return DropdownMenuItem<int>(
          value: m['id'] as int,
          child: Text(m['name'] as String? ?? ''),
        );
      }).toList(),
      onChanged: (v) async {
        setState(() {
          _selectedMosqueId = v;
          _selectedImamId = null;
          _imams = [];
          _mosqueLoading = true;
        });
        if (v != null) {
          final imams = await context.read<AppointmentProvider>().loadImamsForMosque(v);
          if (mounted) setState(() { _imams = imams; _mosqueLoading = false; });
        } else {
          setState(() => _mosqueLoading = false);
        }
      },
      validator: (v) => v == null ? 'Odaberite džamiju' : null,
    );
  }

  Widget _buildImamField() {
    return DropdownButtonFormField<int?>(
      value: _selectedImamId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Imam',
        border: const OutlineInputBorder(),
        suffixIcon: _mosqueLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      hint: Text(
        _selectedMosqueId == null ? 'Prvo odaberite džamiju' : 'Opciono',
        style: const TextStyle(color: AppColors.textLight),
      ),
      disabledHint: const Text('Prvo odaberite džamiju', style: TextStyle(color: AppColors.textLight)),
      items: _imams.map((i) {
        return DropdownMenuItem<int?>(
          value: i['id'] as int,
          child: Text('${i['firstName']} ${i['lastName']}'),
        );
      }).toList(),
      onChanged: _selectedMosqueId == null ? null : (v) => setState(() => _selectedImamId = v),
    );
  }

  Widget _buildDateTimeField() {
    final text = _funeralDateTime != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(_funeralDateTime!)
        : 'Odaberite datum i vrijeme';

    return FormField<DateTime>(
      initialValue: _funeralDateTime,
      validator: (v) {
        if (_funeralDateTime == null) return 'Unesite datum i vrijeme dženaze';
        if (!_isEdit && _funeralDateTime!.isBefore(DateTime.now()))
          return 'Datum dženaze mora biti u budućnosti';
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.calendar_today),
              label: Text(text),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                alignment: Alignment.centerLeft,
                foregroundColor: _funeralDateTime != null ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            if (state.errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: Text(state.errorText!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
              ),
          ],
        );
      },
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    // When editing, allow selecting any date (existing might be in past)
    final earliest = _isEdit ? DateTime(2020) : now;
    final initial = _funeralDateTime ?? now.add(const Duration(hours: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(earliest) ? earliest : initial,
      firstDate: earliest,
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _funeralDateTime != null
          ? TimeOfDay.fromDateTime(_funeralDateTime!)
          : const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null || !mounted) return;

    setState(() {
      _funeralDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Widget _buildCemeteryField(AppointmentProvider p) {
    return DropdownButtonFormField<int>(
      value: _selectedCemeteryId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Groblje *',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Odaberite groblje'),
      items: p.cemeteries.map((c) {
        return DropdownMenuItem<int>(
          value: c['id'] as int,
          child: Text(c['name'] as String? ?? ''),
        );
      }).toList(),
      onChanged: (v) async {
        setState(() {
          _selectedCemeteryId = v;
          _selectedGraveSiteId = null;
          _graveSites = [];
          _cemeteryLoading = true;
        });
        if (v != null) {
          final sites = await context.read<AppointmentProvider>().loadGraveSitesForCemetery(v);
          if (mounted) setState(() { _graveSites = sites; _cemeteryLoading = false; });
        } else {
          setState(() => _cemeteryLoading = false);
        }
      },
      validator: (v) => v == null ? 'Odaberite groblje' : null,
    );
  }

  Widget _buildGraveSiteField() {
    return DropdownButtonFormField<int?>(
      value: _selectedGraveSiteId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Mezarsko mjesto',
        border: const OutlineInputBorder(),
        suffixIcon: _cemeteryLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      hint: Text(
        _selectedCemeteryId == null ? 'Prvo odaberite groblje' : 'Opciono',
        style: const TextStyle(color: AppColors.textLight),
      ),
      disabledHint: const Text('Prvo odaberite groblje', style: TextStyle(color: AppColors.textLight)),
      items: _graveSites.map((s) {
        final sector = s['sectionName'] != null ? ' - ${s['sectionName']}' : '';
        return DropdownMenuItem<int?>(
          value: s['id'] as int,
          child: Text('${s['plotNumber']}$sector'),
        );
      }).toList(),
      onChanged: _selectedCemeteryId == null ? null : (v) => setState(() => _selectedGraveSiteId = v),
    );
  }

  Widget _buildStatusField() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Status *',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'Scheduled', child: Text('Zakazano')),
        DropdownMenuItem(value: 'Held', child: Text('Održano')),
        DropdownMenuItem(value: 'Cancelled', child: Text('Otkazano')),
      ],
      onChanged: (v) => setState(() => _selectedStatus = v ?? 'Scheduled'),
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteCtrl,
      decoration: const InputDecoration(
        labelText: 'Napomena',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
      maxLength: 500,
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Sačuvaj'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'deceasedId': _selectedDeceasedId,
      'mosqueId': _selectedMosqueId,
      'cemeteryId': _selectedCemeteryId,
      'imamId': _selectedImamId,
      'graveSiteId': _selectedGraveSiteId,
      'funeralDateTime': _funeralDateTime!.toUtc().toIso8601String(),
      'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    };

    final p = context.read<AppointmentProvider>();
    bool ok;
    if (_isEdit) {
      data['status'] = _selectedStatus;
      ok = await p.update(widget.appointment!.id, data);
    } else {
      ok = await p.create(data);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Termin ažuriran.' : 'Termin uspješno zakazan.'),
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
