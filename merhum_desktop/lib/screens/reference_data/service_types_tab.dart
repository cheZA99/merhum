import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reference/service_type_model.dart';
import '../../providers/reference_provider.dart';
import '../../utils/constants.dart';

class ServiceTypesTab extends StatelessWidget {
  const ServiceTypesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReferenceProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Vrste usluga', style: AppTextStyles.heading2),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _openDialog(context, provider, null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Dodaj vrstu usluge'),
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (provider.serviceTypes.isEmpty)
              const Center(
                  child: Text('Nema pronađenih vrsta usluga.',
                      style: AppTextStyles.body))
            else
              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(AppColors.background),
                      columns: const [
                        DataColumn(label: Text('Naziv')),
                        DataColumn(label: Text('Opis')),
                        DataColumn(label: Text('Akcije')),
                      ],
                      rows: provider.serviceTypes
                          .map((s) => _buildRow(context, provider, s))
                          .toList(),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  DataRow _buildRow(BuildContext context, ReferenceProvider provider,
      ServiceTypeModel s) {
    return DataRow(cells: [
      DataCell(Text(s.name, style: AppTextStyles.body)),
      DataCell(Text(s.description ?? '-', style: AppTextStyles.body)),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            tooltip: 'Uredi',
            onPressed: () => _openDialog(context, provider, s),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
            tooltip: 'Obriši',
            onPressed: () => _confirmDelete(context, provider, s),
          ),
        ],
      )),
    ]);
  }

  Future<void> _openDialog(BuildContext context, ReferenceProvider provider,
      ServiceTypeModel? serviceType) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: serviceType?.name ?? '');
    final descCtrl =
        TextEditingController(text: serviceType?.description ?? '');
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(serviceType == null
              ? 'Dodaj vrstu usluge'
              : 'Uredi vrstu usluge'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Naziv usluge',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Naziv je obavezan.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Opis',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Odustani'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      final data = {
                        'name': nameCtrl.text.trim(),
                        'description': descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                      };
                      bool success;
                      if (serviceType == null) {
                        success = await provider.createServiceType(data);
                      } else {
                        success = await provider.updateServiceType(
                            serviceType.id, data);
                      }
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              provider.errorMessage ?? 'Greška pri snimanju.'),
                          backgroundColor: AppColors.error,
                        ));
                      }
                    },
              child: const Text('Sačuvaj'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    descCtrl.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, ReferenceProvider provider,
      ServiceTypeModel s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši vrstu usluge'),
        content: Text('Da li ste sigurni da želite obrisati "${s.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.deleteServiceType(s.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Vrsta usluge je uspješno obrisana.'
              : (provider.errorMessage ?? 'Greška pri brisanju.')),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ));
      }
    }
  }
}
