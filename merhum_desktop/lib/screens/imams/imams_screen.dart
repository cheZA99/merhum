import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/imam_model.dart';
import '../../navigation/app_navigation.dart';
import '../../providers/imam_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/sidebar_widget.dart';
import 'imam_form_screen.dart';

class ImamsScreen extends StatefulWidget {
  const ImamsScreen({super.key});

  @override
  State<ImamsScreen> createState() => _ImamsScreenState();
}

class _ImamsScreenState extends State<ImamsScreen> {
  bool _isNavigating = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ImamProvider>();
      p.loadAll();
      p.loadMosques();
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
            selectedIndex: 7,
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
    return Consumer<ImamProvider>(
      builder: (context, provider, _) {
        return Row(
          children: [
            const Text('Imami', style: AppTextStyles.heading1),
            const SizedBox(width: 24),
            SizedBox(
              width: 300,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Pretraži po imenu...',
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
                value: provider.filterMosqueId,
                hint: const Text('Svi mesdžidi'),
                isExpanded: true,
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null, child: Text('Svi mesdžidi')),
                  ...provider.mosques.map((m) => DropdownMenuItem<int?>(
                        value: m['id'] as int,
                        child: Text(m['name'] as String? ?? ''),
                      )),
                ],
                onChanged: (v) => provider.setFilterMosque(v),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _openForm(context, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Dodaj imama'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    return Consumer<ImamProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null && provider.imams.isEmpty) {
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

        if (provider.imams.isEmpty) {
          return const Center(
            child: Text('Nema pronađenih imama.', style: AppTextStyles.body),
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
            Expanded(child: _buildTable(context, provider)),
            const SizedBox(height: 12),
            _buildPagination(provider),
          ],
        );
      },
    );
  }

  Widget _buildTable(BuildContext context, ImamProvider provider) {
    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.background),
          columns: const [
            DataColumn(label: Text('Ime')),
            DataColumn(label: Text('Prezime')),
            DataColumn(label: Text('Mesdžid')),
            DataColumn(label: Text('Telefon')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Aktivan')),
            DataColumn(label: Text('Akcije')),
          ],
          rows: provider.imams
              .map((m) => _buildRow(context, m, provider))
              .toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(
      BuildContext context, ImamModel m, ImamProvider provider) {
    return DataRow(cells: [
      DataCell(Text(m.firstName, style: AppTextStyles.body)),
      DataCell(Text(m.lastName, style: AppTextStyles.body)),
      DataCell(Text(m.mosqueName, style: AppTextStyles.body)),
      DataCell(Text(m.phone, style: AppTextStyles.body)),
      DataCell(Text(m.email ?? '-', style: AppTextStyles.body)),
      DataCell(
        Icon(
          m.isActive ? Icons.check_circle : Icons.cancel,
          color: m.isActive ? AppColors.success : AppColors.error,
          size: 20,
        ),
      ),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            tooltip: 'Uredi',
            onPressed: () => _openForm(context, m),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
            tooltip: 'Obriši',
            onPressed: () => _confirmDelete(context, m, provider),
          ),
        ],
      )),
    ]);
  }

  Widget _buildPagination(ImamProvider provider) {
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

  Future<void> _openForm(BuildContext context, ImamModel? imam) async {
    setState(() => _isNavigating = true);
    context.read<ImamProvider>().clearError();

    final result = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<ImamProvider>(),
          child: ImamFormScreen(imam: imam),
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _isNavigating = false);
    context.read<ImamProvider>().clearError();

    if (result == 'created') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Imam je uspješno dodan.'),
        backgroundColor: AppColors.success,
      ));
    } else if (result == 'updated') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Imam je uspješno ažuriran.'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, ImamModel m, ImamProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši imama'),
        content: Text(
            'Da li ste sigurni da želite obrisati ${m.fullName}?\nOva akcija se ne može poništiti.'),
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
      final success = await provider.delete(m.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Imam je uspješno obrisan.'
              : (provider.errorMessage ?? 'Greška pri brisanju.')),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ));
      }
    }
  }
}
