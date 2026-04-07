import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reference/country_model.dart';
import '../../providers/reference_provider.dart';
import '../../utils/constants.dart';

class CountriesTab extends StatelessWidget {
  const CountriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReferenceProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Države', style: AppTextStyles.heading2),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _openDialog(context, provider, null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Dodaj državu'),
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (provider.countries.isEmpty)
              const Center(
                  child: Text('Nema pronađenih država.', style: AppTextStyles.body))
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
                        DataColumn(label: Text('Kod')),
                        DataColumn(label: Text('Akcije')),
                      ],
                      rows: provider.countries
                          .map((c) => _buildRow(context, provider, c))
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

  DataRow _buildRow(
      BuildContext context, ReferenceProvider provider, CountryModel c) {
    return DataRow(cells: [
      DataCell(Text(c.name, style: AppTextStyles.body)),
      DataCell(Text(c.code, style: AppTextStyles.body)),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            tooltip: 'Uredi',
            onPressed: () => _openDialog(context, provider, c),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
            tooltip: 'Obriši',
            onPressed: () => _confirmDelete(context, provider, c),
          ),
        ],
      )),
    ]);
  }

  Future<void> _openDialog(
      BuildContext context, ReferenceProvider provider, CountryModel? country) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: country?.name ?? '');
    final codeCtrl = TextEditingController(text: country?.code ?? '');
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(country == null ? 'Dodaj državu' : 'Uredi državu'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Naziv države',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Naziv je obavezan.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kod',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 3,
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Kod je obavezan.' : null,
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
                        'code': codeCtrl.text.trim().toUpperCase(),
                      };
                      bool success;
                      if (country == null) {
                        success = await provider.createCountry(data);
                      } else {
                        success = await provider.updateCountry(country.id, data);
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
    codeCtrl.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, ReferenceProvider provider,
      CountryModel country) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši državu'),
        content: Text('Da li ste sigurni da želite obrisati "${country.name}"?'),
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
      final success = await provider.deleteCountry(country.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Država je uspješno obrisana.'
              : (provider.errorMessage ?? 'Greška pri brisanju.')),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ));
      }
    }
  }
}
