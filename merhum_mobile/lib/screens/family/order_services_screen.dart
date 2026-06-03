import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/service_order_provider.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';

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
  int? _serviceTypeId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = context.read<ServiceOrderProvider>();
      sp.loadFuneralHomes();
      sp.loadServiceTypes();
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final ok = await context.read<ServiceOrderProvider>().create({
      'deceasedId': widget.deceasedId,
      'funeralHomeId': _funeralHomeId,
      'serviceTypeId': _serviceTypeId,
      'notes': _notesCtrl.text.trim(),
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

  double? _selectedPrice(List<Map<String, dynamic>> types) {
    if (_serviceTypeId == null) return null;
    final t = types.firstWhere((e) => e['id'] == _serviceTypeId, orElse: () => {});
    final p = t['price'];
    if (p == null) return null;
    return (p as num).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<ServiceOrderProvider>();
    final price = _selectedPrice(sp.serviceTypes);
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
                  onChanged: (v) => setState(() => _funeralHomeId = v),
                  validator: (v) => v == null ? 'Obavezno polje' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _serviceTypeId,
                  decoration: const InputDecoration(labelText: 'Vrsta usluge'),
                  items: sp.serviceTypes.map((s) => DropdownMenuItem<int>(
                    value: s['id'] as int,
                    child: Text(s['name'] as String? ?? ''),
                  )).toList(),
                  onChanged: (v) => setState(() => _serviceTypeId = v),
                  validator: (v) => v == null ? 'Obavezno polje' : null,
                ),
                if (price != null) ...[
                  const SizedBox(height: 14),
                  Card(
                    color: AppColors.primaryLight.withOpacity(0.12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_money, color: AppColors.primary),
                          const SizedBox(width: 8),
                          const Text('Cijena: ', style: AppTextStyles.body),
                          Text(DateFormatter.money(price), style: AppTextStyles.heading3),
                        ],
                      ),
                    ),
                  ),
                ],
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
