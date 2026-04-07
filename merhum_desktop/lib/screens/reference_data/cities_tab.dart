import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reference/city_model.dart';
import '../../providers/reference_provider.dart';
import '../../utils/constants.dart';

class CitiesTab extends StatelessWidget {
  const CitiesTab({super.key});

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
                    value: provider.filterCountryId,
                    hint: const Text('Sve države'),
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('Sve države')),
                      ...provider.countries.map((c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.name),
                          )),
                    ],
                    onChanged: (v) {
                      provider.filterCountryId = v;
                      if (v != null) {
                        provider.loadCities(countryId: v);
                      } else {
                        provider.loadCities();
                      }
                    },
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _openDialog(context, provider, null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Dodaj grad'),
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (provider.cities.isEmpty)
              const Center(
                  child: Text('Nema pronađenih gradova.', style: AppTextStyles.body))
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
                        DataColumn(label: Text('Poštanski broj')),
                        DataColumn(label: Text('Država')),
                        DataColumn(label: Text('Akcije')),
                      ],
                      rows: provider.cities
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
      BuildContext context, ReferenceProvider provider, CityModel c) {
    return DataRow(cells: [
      DataCell(Text(c.name, style: AppTextStyles.body)),
      DataCell(Text(c.postalCode ?? '-', style: AppTextStyles.body)),
      DataCell(Text(c.countryName, style: AppTextStyles.body)),
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
      BuildContext context, ReferenceProvider provider, CityModel? city) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: city?.name ?? '');
    final postalCtrl = TextEditingController(text: city?.postalCode ?? '');
    int? selectedCountryId = city?.countryId;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(city == null ? 'Dodaj grad' : 'Uredi grad'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Naziv grada',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Naziv je obavezan.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: postalCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Poštanski broj',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedCountryId,
                  decoration: const InputDecoration(
                    labelText: 'Država',
                    border: OutlineInputBorder(),
                  ),
                  items: provider.countries
                      .map((c) => DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedCountryId = v),
                  validator: (v) => v == null ? 'Država je obavezna.' : null,
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
                        'postalCode': postalCtrl.text.trim().isEmpty
                            ? null
                            : postalCtrl.text.trim(),
                        'countryId': selectedCountryId,
                      };
                      bool success;
                      if (city == null) {
                        success = await provider.createCity(data);
                      } else {
                        success = await provider.updateCity(city.id, data);
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
    postalCtrl.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, ReferenceProvider provider,
      CityModel city) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši grad'),
        content: Text('Da li ste sigurni da želite obrisati "${city.name}"?'),
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
      final success = await provider.deleteCity(city.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Grad je uspješno obrisan.'
              : (provider.errorMessage ?? 'Greška pri brisanju.')),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ));
      }
    }
  }
}
