import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/appointment_provider.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';

class ScheduleAppointmentScreen extends StatefulWidget {
  final int deceasedId;
  const ScheduleAppointmentScreen({super.key, required this.deceasedId});

  @override
  State<ScheduleAppointmentScreen> createState() => _ScheduleAppointmentScreenState();
}

class _ScheduleAppointmentScreenState extends State<ScheduleAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  int? _mosqueId;
  int? _imamId;
  int? _cemeteryId;
  int? _graveSiteId;
  DateTime? _date;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ap = context.read<AppointmentProvider>();
      ap.loadMosques();
      ap.loadCemeteries();
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 12, minute: 0));
    if (time == null) return;
    setState(() => _date = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Odaberite datum i vrijeme'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _submitting = true);
    final ok = await context.read<AppointmentProvider>().createAppointment({
      'deceasedId': widget.deceasedId,
      'mosqueId': _mosqueId,
      'imamId': _imamId,
      'funeralDateTime': _date!.toIso8601String(),
      'cemeteryId': _cemeteryId,
      'graveSiteId': _graveSiteId,
      'notes': _notesCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Termin uspješno zakazan'), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Greška pri zakazivanju'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AppointmentProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Zakaži termin')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  value: _mosqueId,
                  decoration: const InputDecoration(labelText: 'Džamija'),
                  items: ap.mosques.map((m) => DropdownMenuItem<int>(
                    value: m['id'] as int,
                    child: Text(m['name'] as String? ?? ''),
                  )).toList(),
                  onChanged: (v) {
                    setState(() {
                      _mosqueId = v;
                      _imamId = null;
                    });
                    if (v != null) context.read<AppointmentProvider>().loadImamsByMosque(v);
                  },
                  validator: (v) => v == null ? 'Obavezno polje' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _imamId,
                  decoration: const InputDecoration(labelText: 'Imam'),
                  items: ap.imams.map((i) => DropdownMenuItem<int>(
                    value: i['id'] as int,
                    child: Text(i['fullName'] as String? ?? i['name'] as String? ?? ''),
                  )).toList(),
                  onChanged: (v) => setState(() => _imamId = v),
                  validator: (v) => v == null ? 'Obavezno polje' : null,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDateTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Datum i vrijeme',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      _date == null ? 'Odaberi datum i vrijeme' : DateFormatter.dateTime(_date),
                      style: _date == null ? AppTextStyles.bodyMedium : AppTextStyles.body,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _cemeteryId,
                  decoration: const InputDecoration(labelText: 'Groblje'),
                  items: ap.cemeteries.map((c) => DropdownMenuItem<int>(
                    value: c['id'] as int,
                    child: Text(c['name'] as String? ?? ''),
                  )).toList(),
                  onChanged: (v) {
                    setState(() {
                      _cemeteryId = v;
                      _graveSiteId = null;
                    });
                    if (v != null) context.read<AppointmentProvider>().loadGraveSites(v);
                  },
                  validator: (v) => v == null ? 'Obavezno polje' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _graveSiteId,
                  decoration: const InputDecoration(labelText: 'Mezarsko mjesto'),
                  items: ap.graveSites.map((g) => DropdownMenuItem<int>(
                    value: g['id'] as int,
                    child: Text(g['number'] as String? ?? g['name'] as String? ?? ''),
                  )).toList(),
                  onChanged: (v) => setState(() => _graveSiteId = v),
                  validator: (v) => v == null ? 'Obavezno polje' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Napomena'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Zakaži termin'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
