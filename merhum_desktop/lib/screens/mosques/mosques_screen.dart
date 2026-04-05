import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/mosque_model.dart';
import '../../providers/mosque_provider.dart';
import '../../navigation/app_navigation.dart';
import '../../utils/constants.dart';
import '../../widgets/sidebar_widget.dart';
import 'mosque_form_screen.dart';

class MosquesScreen extends StatefulWidget {
  const MosquesScreen({super.key});

  @override
  State<MosquesScreen> createState() => _MosquesScreenState();
}

class _MosquesScreenState extends State<MosquesScreen> {
  int _currentPage = 0;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<MosqueProvider>();
      p.loadAll();
      p.loadGradovi();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarWidget(
            selectedIndex: 4,
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
    return Consumer<MosqueProvider>(
      builder: (context, provider, _) {
        return Row(
          children: [
            const Text('Mesdžidi', style: AppTextStyles.heading1),
            const Spacer(),
            SizedBox(
              width: 220,
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
                  setState(() => _currentPage = 0);
                  provider.setSearch(v);
                },
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<int?>(
              value: provider.filterGradId,
              hint: const Text('Svi gradovi'),
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem<int?>(
                    value: null, child: Text('Svi gradovi')),
                ...provider.gradovi.map((g) => DropdownMenuItem<int?>(
                      value: g['id'] as int,
                      child: Text(g['name'] as String? ?? ''),
                    )),
              ],
              onChanged: (v) {
                setState(() => _currentPage = 0);
                provider.setFilterGrad(v);
              },
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _openForm(context, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Dodaj mesdžid'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    return Consumer<MosqueProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(provider.errorMessage!,
                    style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 12),
                TextButton(
                    onPressed: provider.loadAll, child: const Text('Pokusaj ponovo')),
              ],
            ),
          );
        }

        final allItems = provider.stavke;

        if (allItems.isEmpty) {
          return const Center(
            child: Text('Nema mesdžida.', style: AppTextStyles.body),
          );
        }

        final totalPages = (allItems.length / _pageSize).ceil().clamp(1, 999);
        final pageItems = allItems
            .skip(_currentPage * _pageSize)
            .take(_pageSize)
            .toList();

        return Column(
          children: [
            Expanded(child: _buildTable(context, pageItems, provider)),
            const SizedBox(height: 12),
            _buildPagination(allItems.length, totalPages),
          ],
        );
      },
    );
  }

  Widget _buildTable(
      BuildContext context, List<MosqueModel> items, MosqueProvider provider) {
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
            DataColumn(label: Text('Kapacitet')),
            DataColumn(label: Text('Aktivan')),
            DataColumn(label: Text('Akcije')),
          ],
          rows: items.map((m) => _buildRow(context, m, provider)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(
      BuildContext context, MosqueModel m, MosqueProvider provider) {
    return DataRow(cells: [
      DataCell(Text(m.naziv, style: AppTextStyles.body)),
      DataCell(Text(m.gradNaziv, style: AppTextStyles.body)),
      DataCell(Text(m.telefon ?? '-', style: AppTextStyles.body)),
      DataCell(Text(m.email ?? '-', style: AppTextStyles.body)),
      DataCell(Text(
          m.kapacitet != null ? m.kapacitet.toString() : '-',
          style: AppTextStyles.body)),
      DataCell(
        Icon(
          m.jeAktivan ? Icons.check_circle : Icons.cancel,
          color: m.jeAktivan ? AppColors.success : AppColors.error,
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

  Widget _buildPagination(int total, int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed:
              _currentPage > 0 ? () => setState(() => _currentPage--) : null,
        ),
        Text(
          'Stranica ${_currentPage + 1} od $totalPages  ($total ukupno)',
          style: AppTextStyles.caption,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _currentPage < totalPages - 1
              ? () => setState(() => _currentPage++)
              : null,
        ),
      ],
    );
  }

  Future<void> _openForm(BuildContext context, MosqueModel? mosque) async {
    final result = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<MosqueProvider>(),
          child: MosqueFormScreen(mosque: mosque),
        ),
      ),
    );

    if (!mounted) return;

    if (result == 'created') {
      setState(() => _currentPage = 0);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mesdžid uspješno dodan.'),
        backgroundColor: AppColors.success,
      ));
    } else if (result == 'updated') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mesdžid uspješno ažuriran.'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, MosqueModel m, MosqueProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content:
            Text('Jeste li sigurni da želite obrisati mesdžid "${m.naziv}"?'),
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
              ? 'Mesdžid uspješno obrisan.'
              : (provider.errorMessage ?? 'Greška pri brisanju.')),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ));
      }
    }
  }
}
