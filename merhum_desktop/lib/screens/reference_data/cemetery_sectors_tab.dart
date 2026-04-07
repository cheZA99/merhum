import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reference/cemetery_sector_model.dart';
import '../../providers/reference_provider.dart';
import '../../utils/constants.dart';

class CemeterySectorsTab extends StatelessWidget {
  const CemeterySectorsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReferenceProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButton<int?>(
                    value: provider.filterCemeteryId,
                    hint: const Text('Sva groblja'),
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('Sva groblja')),
                      ...provider.cemeteries.map((c) => DropdownMenuItem<int?>(
                            value: c['id'] as int,
                            child: Text(c['name'] as String? ?? ''),
                          )),
                    ],
                    onChanged: (v) {
                      provider.filterCemeteryId = v;
                      if (v != null) {
                        provider.loadSectors(cemeteryId: v);
                      } else {
                        provider.loadSectors();
                      }
                    },
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _openDialog(context, provider, null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Dodaj sektor'),
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (provider.sectors.isEmpty)
              const Center(
                  child: Text('Nema pronađenih sektora.', style: AppTextStyles.body))
            else
              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(AppColors.background),
                      columns: const [
                        DataColumn(label: Text('Naziv sektora')),
                        DataColumn(label: Text('Groblje')),
                        DataColumn(label: Text('Akcije')),
                      ],
                      rows: provider.sectors
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

  String _cemeteryName(ReferenceProvider provider, int cemeteryId) {
    final match = provider.cemeteries.firstWhere(
      (c) => c['id'] == cemeteryId,
      orElse: () => <String, dynamic>{},
    );
    return match['name'] as String? ?? '';
  }

  DataRow _buildRow(BuildContext context, ReferenceProvider provider,
      CemeterySectorModel s) {
    final displayName = s.cemeteryName.isNotEmpty
        ? s.cemeteryName
        : _cemeteryName(provider, s.cemeteryId);

    return DataRow(cells: [
      DataCell(Text(s.name, style: AppTextStyles.body)),
      DataCell(Text(displayName, style: AppTextStyles.body)),
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
      CemeterySectorModel? sector) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: sector?.name ?? '');
    int? selectedCemeteryId = sector?.cemeteryId;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(sector == null ? 'Dodaj sektor' : 'Uredi sektor'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Naziv sektora',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Naziv je obavezan.' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedCemeteryId,
                  decoration: const InputDecoration(
                    labelText: 'Groblje',
                    border: OutlineInputBorder(),
                  ),
                  items: provider.cemeteries
                      .map((c) => DropdownMenuItem<int>(
                            value: c['id'] as int,
                            child: Text(c['name'] as String? ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedCemeteryId = v),
                  validator: (v) => v == null ? 'Groblje je obavezno.' : null,
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
                        'cemeteryId': selectedCemeteryId,
                      };
                      bool success;
                      if (sector == null) {
                        success = await provider.createSector(data);
                      } else {
                        success =
                            await provider.updateSector(sector.id, data);
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
  }

  Future<void> _confirmDelete(BuildContext context, ReferenceProvider provider,
      CemeterySectorModel s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši sektor'),
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
      final success = await provider.deleteSector(s.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Sektor je uspješno obrisan.'
              : (provider.errorMessage ?? 'Greška pri brisanju.')),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ));
      }
    }
  }
}
