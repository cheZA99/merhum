import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/funeral_home_model.dart';
import '../../navigation/app_navigation.dart';
import '../../providers/funeral_home_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/sidebar_widget.dart';
import 'funeral_home_form_screen.dart';

class FuneralHomesScreen extends StatefulWidget {
  const FuneralHomesScreen({super.key});

  @override
  State<FuneralHomesScreen> createState() => _FuneralHomesScreenState();
}

class _FuneralHomesScreenState extends State<FuneralHomesScreen> {
  bool _isNavigating = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<FuneralHomeProvider>();
      p.loadAll();
      p.loadCities();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarWidget(
            selectedIndex: 8,
            onItemSelected: (i) => navigateByIndex(context, i),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<FuneralHomeProvider>(
      builder: (context, provider, _) {
        return Row(
          children: [
            const Text('Pogrebna preduzeća', style: AppTextStyles.heading1),
            const SizedBox(width: 24),
            SizedBox(
              width: 300,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Pretraži po nazivu...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
                onChanged: (v) {
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                    provider.setSearch(v);
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 200,
              child: DropdownButton<int?>(
                value: provider.filterCityId,
                hint: const Text('Svi gradovi'),
                isExpanded: true,
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null, child: Text('Svi gradovi')),
                  ...provider.cities.map((c) => DropdownMenuItem<int?>(
                        value: c['id'] as int,
                        child: Text(c['name'] as String? ?? ''),
                      )),
                ],
                onChanged: (v) => provider.setFilterCity(v),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _openForm(context, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Dodaj pogrebno preduzeće'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    return Consumer<FuneralHomeProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = provider.funeralHomes;

        if (provider.errorMessage != null && items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(provider.errorMessage!,
                    style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 12),
                TextButton(
                    onPressed: provider.loadAll,
                    child: const Text('Pokušaj ponovo')),
              ],
            ),
          );
        }

        if (items.isEmpty) {
          return const Center(
            child: Text('Nema pronađenih pogrebnih preduzeća.',
                style: AppTextStyles.body),
          );
        }

        return Column(
          children: [
            if (provider.errorMessage != null && !_isNavigating)
              Container(
                width: double.infinity,
                color: AppColors.error.withValues(alpha: 0.1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(provider.errorMessage!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 13)),
              ),
            Expanded(child: _buildTable(context, items, provider)),
            const SizedBox(height: 12),
            _buildPagination(provider),
          ],
        );
      },
    );
  }

  Widget _buildTable(BuildContext context, List<FuneralHomeModel> items,
      FuneralHomeProvider provider) {
    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.background),
          columns: const [
            DataColumn(label: Text('Naziv')),
            DataColumn(label: Text('Grad')),
            DataColumn(label: Text('Telefon')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Licencni broj')),
            DataColumn(label: Text('Aktivan')),
            DataColumn(label: Text('Akcije')),
          ],
          rows: items.map((h) => _buildRow(context, h, provider)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, FuneralHomeModel h,
      FuneralHomeProvider provider) {
    return DataRow(cells: [
      DataCell(Text(h.name, style: AppTextStyles.body)),
      DataCell(Text(h.cityName, style: AppTextStyles.body)),
      DataCell(Text(h.phone, style: AppTextStyles.body)),
      DataCell(Text(h.email ?? '-', style: AppTextStyles.body)),
      DataCell(Text(h.licenseNumber ?? '-', style: AppTextStyles.body)),
      DataCell(
        Icon(
          h.isActive ? Icons.check_circle : Icons.cancel,
          color: h.isActive ? AppColors.success : AppColors.error,
          size: 20,
        ),
      ),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            tooltip: 'Uredi',
            onPressed: () => _openForm(context, h),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
            tooltip: 'Obriši',
            onPressed: () => _confirmDelete(context, h, provider),
          ),
        ],
      )),
    ]);
  }

  Widget _buildPagination(FuneralHomeProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: provider.currentPage > 1
              ? () => provider.loadAll(page: provider.currentPage - 1)
              : null,
        ),
        Text(
          'Stranica ${provider.currentPage} od ${provider.totalPages}',
          style: AppTextStyles.caption,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: provider.currentPage < provider.totalPages
              ? () => provider.loadAll(page: provider.currentPage + 1)
              : null,
        ),
      ],
    );
  }

  Future<void> _openForm(BuildContext context, FuneralHomeModel? home) async {
    setState(() => _isNavigating = true);
    context.read<FuneralHomeProvider>().clearError();

    final result = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<FuneralHomeProvider>(),
          child: FuneralHomeFormScreen(home: home),
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _isNavigating = false);
    context.read<FuneralHomeProvider>().clearError();

    if (result == 'created') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pogrebno preduzeće je uspješno dodano.'),
        backgroundColor: AppColors.success,
      ));
    } else if (result == 'updated') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pogrebno preduzeće je uspješno ažurirano.'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  Future<void> _confirmDelete(BuildContext context, FuneralHomeModel h,
      FuneralHomeProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši pogrebno preduzeće'),
        content: Text(
            'Da li ste sigurni da želite obrisati "${h.name}"?\nOva akcija se ne može poništiti.'),
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

    if (confirmed == true && mounted) {
      final success = await provider.delete(h.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Pogrebno preduzeće je uspješno obrisano.'
              : (provider.errorMessage ?? 'Greška pri brisanju.')),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ));
      }
    }
  }
}
