import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/service_order_provider.dart';
import '../../utils/constants.dart';

class OrderServicesScreen extends StatefulWidget {
  final int deceasedId;
  const OrderServicesScreen({super.key, required this.deceasedId});

  @override
  State<OrderServicesScreen> createState() => _OrderServicesScreenState();
}

class _OrderServicesScreenState extends State<OrderServicesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  int? _funeralHomeId;
  int? _offeringId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceOrderProvider>().loadFuneralHomes();
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _selectedOffering {
    final offerings = context.read<ServiceOrderProvider>().offerings;
    for (final o in offerings) {
      if (o['id'] == _offeringId) return o;
    }
    return null;
  }

  Future<bool> _confirm() async {
    final offering = _selectedOffering;
    if (offering == null) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda narudžbe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Usluga: ${offering['serviceTypeName'] ?? ''}', style: AppTextStyles.body),
            const SizedBox(height: 6),
            Text('Preduzeće: ${offering['funeralHomeName'] ?? ''}', style: AppTextStyles.body),
            const SizedBox(height: 6),
            Text('Cijena: ${offering['price']} KM', style: AppTextStyles.heading3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Odustani')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Naruči')),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!await _confirm()) return;
    if (!mounted) return;

    setState(() => _submitting = true);
    // the price is not sent, the server reads it from the chosen offering
    final ok = await context.read<ServiceOrderProvider>().create({
      'deceasedId': widget.deceasedId,
      'serviceOfferingId': _offeringId,
      'note': _notesCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Narudžba uspješno kreirana'), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Greška pri kreiranju narudžbe'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<ServiceOrderProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Naruči usluge')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  value: _funeralHomeId,
                  decoration: const InputDecoration(labelText: 'Pogrebno preduzeće'),
                  items: sp.funeralHomes.map((f) => DropdownMenuItem<int>(
                    value: f['id'] as int,
                    child: Text(f['name'] as String? ?? ''),
                  )).toList(),
                  onChanged: (v) {
                    setState(() {
                      _funeralHomeId = v;
                      _offeringId = null;
                    });
                    if (v != null) context.read<ServiceOrderProvider>().loadOfferings(v);
                  },
                  validator: (v) => v == null ? 'Obavezno polje' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _offeringId,
                  decoration: const InputDecoration(labelText: 'Usluga i cijena'),
                  items: sp.offerings.map((o) => DropdownMenuItem<int>(
                    value: o['id'] as int,
                    child: Text('${o['serviceTypeName'] ?? ''} - ${o['price']} KM'),
                  )).toList(),
                  onChanged: (v) => setState(() => _offeringId = v),
                  validator: (v) => v == null ? 'Obavezno polje' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Napomena'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Naruči'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
