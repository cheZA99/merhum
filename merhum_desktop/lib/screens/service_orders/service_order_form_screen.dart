import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/service_order_model.dart';
import '../../providers/service_order_provider.dart';
import '../../utils/constants.dart';

class ServiceOrderFormScreen extends StatefulWidget {
  final ServiceOrderModel? order;
  final int? preselectedDeceasedId;

  const ServiceOrderFormScreen({
    super.key,
    this.order,
    this.preselectedDeceasedId,
  });

  @override
  State<ServiceOrderFormScreen> createState() => _ServiceOrderFormScreenState();
}

class _ServiceOrderFormScreenState extends State<ServiceOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedDeceasedId;
  int? _selectedFuneralHomeId;
  int? _selectedOfferingId;
  String _selectedStatus = 'Ordered';
  DateTime? _completedAt;
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isSaving = false;

  bool get _isEdit => widget.order != null;

  @override
  void initState() {
    super.initState();
    final o = widget.order;
    if (o != null) {
      _selectedDeceasedId = o.deceasedId;
      _selectedFuneralHomeId = o.funeralHomeId;
      _selectedOfferingId = o.serviceOfferingId;
      _selectedStatus = o.status;
      _completedAt = o.completedAt?.toLocal();
      _priceCtrl.text = o.price.toStringAsFixed(2);
      _noteCtrl.text = o.note ?? '';
    } else if (widget.preselectedDeceasedId != null) {
      _selectedDeceasedId = widget.preselectedDeceasedId;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ServiceOrderProvider>();
      provider.loadDropdownData();
      if (_selectedFuneralHomeId != null) provider.loadOfferings(_selectedFuneralHomeId!);
    });
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Uredi nalog' : 'Novi nalog'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Consumer<ServiceOrderProvider>(
        builder: (context, p, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeceasedField(p),
                  const SizedBox(height: 16),
                  _buildFuneralHomeField(p),
                  const SizedBox(height: 16),
                  _buildOfferingField(p),
                  const SizedBox(height: 16),
                  _buildStatusField(),
                  const SizedBox(height: 16),
                  if (_selectedStatus == 'Completed') ...[
                    _buildCompletedAtField(),
                    const SizedBox(height: 16),
                  ],
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

  Widget _buildDeceasedField(ServiceOrderProvider p) {
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

  Widget _buildFuneralHomeField(ServiceOrderProvider p) {
    return DropdownButtonFormField<int>(
      value: _selectedFuneralHomeId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Pogrebno preduzeće *',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Odaberite pogrebno preduzeće'),
      items: p.funeralHomes.map((f) {
        return DropdownMenuItem<int>(
          value: f['id'] as int,
          child: Text(f['name'] as String? ?? ''),
        );
      }).toList(),
      onChanged: (v) {
        setState(() {
          _selectedFuneralHomeId = v;
          _selectedOfferingId = null;
        });
        if (v != null) context.read<ServiceOrderProvider>().loadOfferings(v);
      },
      validator: (v) => v == null ? 'Odaberite pogrebno preduzeće' : null,
    );
  }

  Widget _buildOfferingField(ServiceOrderProvider p) {
    return DropdownButtonFormField<int>(
      value: _selectedOfferingId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Usluga i cijena *',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Odaberite uslugu iz cjenovnika'),
      items: p.offerings.map((o) {
        return DropdownMenuItem<int>(
          value: o['id'] as int,
          child: Text('${o['serviceTypeName'] ?? ''} - ${o['price']} KM'),
        );
      }).toList(),
      onChanged: (v) => setState(() => _selectedOfferingId = v),
      validator: (v) => v == null ? 'Odaberite uslugu' : null,
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
        DropdownMenuItem(value: 'Ordered', child: Text('Naručeno')),
        DropdownMenuItem(value: 'InProgress', child: Text('U toku')),
        DropdownMenuItem(value: 'Completed', child: Text('Završeno')),
      ],
      onChanged: (v) {
        setState(() {
          _selectedStatus = v ?? 'Ordered';
          if (_selectedStatus == 'Completed' && _completedAt == null) {
            _completedAt = DateTime.now();
          }
        });
      },
    );
  }

  Widget _buildCompletedAtField() {
    final text = _completedAt != null
        ? DateFormat('dd.MM.yyyy').format(_completedAt!)
        : 'Odaberite datum';

    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _completedAt ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _completedAt = picked);
      },
      icon: const Icon(Icons.calendar_today),
      label: Text('Datum završetka: $text'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        alignment: Alignment.centerLeft,
      ),
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

    // the price comes from the chosen offering, the server never takes it from here
    final data = {
      'deceasedId': _selectedDeceasedId,
      'serviceOfferingId': _selectedOfferingId,
      'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    };

    final p = context.read<ServiceOrderProvider>();
    bool ok;
    if (_isEdit) {
      ok = await p.update(widget.order!.id, data);
      // status has its own endpoint, so it is applied separately when it changed
      if (ok && _selectedStatus != widget.order!.status) {
        ok = await p.changeStatus(widget.order!.id, _selectedStatus);
      }
    } else {
      ok = await p.create(data);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Nalog ažuriran.' : 'Nalog uspješno dodan.'),
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
