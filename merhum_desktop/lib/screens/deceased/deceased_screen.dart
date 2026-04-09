import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/deceased_model.dart';
import '../../navigation/app_navigation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/deceased_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/sidebar_widget.dart';
import 'deceased_details_screen.dart';
import 'deceased_form_screen.dart';
import 'widgets/status_chip_widget.dart';

class DeceasedScreen extends StatefulWidget {
  const DeceasedScreen({super.key});

  @override
  State<DeceasedScreen> createState() => _DeceasedScreenState();
}

class _DeceasedScreenState extends State<DeceasedScreen> {
  bool _isNavigating = false;
  Timer? _searchDebounce;
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<DeceasedProvider>();
      p.loadAll();
      p.loadStatuses();
      p.loadCities();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      final combined =
          '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();
      context.read<DeceasedProvider>().setSearch(combined);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarWidget(
            selectedIndex: 1,
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
    return Consumer<DeceasedProvider>(
      builder: (context, provider, _) {
        return Row(
          children: [
            const Text('Preminuli', style: AppTextStyles.heading1),
            const SizedBox(width: 16),
            SizedBox(
              width: 180,
              child: TextField(
                controller: _firstNameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ime...',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
                onChanged: (_) => _onSearchChanged(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 180,
              child: TextField(
                controller: _lastNameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Prezime...',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
                onChanged: (_) => _onSearchChanged(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 160,
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
            const SizedBox(width: 8),
            SizedBox(
              width: 200,
              child: DropdownButton<int?>(
                value: provider.filterStatusId,
                hint: const Text('Svi statusi'),
                isExpanded: true,
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null, child: Text('Svi statusi')),
                  ...provider.statuses.map((s) => DropdownMenuItem<int?>(
                        value: s.id,
                        child:
                            Text(StatusChipWidget.labelFor(s.name)),
                      )),
                ],
                onChanged: (v) => provider.setFilterStatus(v),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                _firstNameCtrl.clear();
                _lastNameCtrl.clear();
                provider.resetFilters();
              },
              child: const Text('Resetuj filtere'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _openForm(context, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Registruj preminulog'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    return Consumer<DeceasedProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null && provider.deceasedList.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(provider.errorMessage!,
                    style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: provider.loadAll,
                  child: const Text('Pokušaj ponovo'),
                ),
              ],
            ),
          );
        }

        if (provider.totalCount == 0) {
          return const Center(
            child: Text('Nema pronađenih preminulih.',
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
            Expanded(child: _buildTable(context, provider)),
            const SizedBox(height: 12),
            _buildPagination(provider),
          ],
        );
      },
    );
  }

  Widget _buildTable(BuildContext context, DeceasedProvider provider) {
    final auth = context.watch<AuthProvider>();
    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.background),
          columns: const [
            DataColumn(label: Text('Ime i prezime')),
            DataColumn(label: Text('Grad')),
            DataColumn(label: Text('Datum smrti')),
            DataColumn(label: Text('Godine')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Kontakt osoba')),
            DataColumn(label: Text('Registrovao')),
            DataColumn(label: Text('Akcije')),
          ],
          rows: provider.deceasedList
              .map((d) => _buildRow(context, d, provider, auth))
              .toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(
    BuildContext context,
    DeceasedModel d,
    DeceasedProvider provider,
    AuthProvider auth,
  ) {
    final dateOfDeath =
        '${d.dateOfDeath.day.toString().padLeft(2, '0')}.${d.dateOfDeath.month.toString().padLeft(2, '0')}.${d.dateOfDeath.year}';

    return DataRow(cells: [
      DataCell(Text(d.fullName, style: AppTextStyles.body)),
      DataCell(Text(d.cityName, style: AppTextStyles.body)),
      DataCell(Text(dateOfDeath, style: AppTextStyles.body)),
      DataCell(Text('${d.ageAtDeath}', style: AppTextStyles.body)),
      DataCell(StatusChipWidget(statusName: d.procedureStatusName)),
      DataCell(Text(d.contactPersonName, style: AppTextStyles.body)),
      DataCell(Text(d.createdByUsername, style: AppTextStyles.body)),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility, size: 18),
            tooltip: 'Detalji',
            onPressed: () => _openDetails(context, d, provider),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            tooltip: 'Uredi',
            onPressed: () => _openForm(context, d),
          ),
          if (auth.role == 'Administrator')
            IconButton(
              icon:
                  const Icon(Icons.delete, size: 18, color: AppColors.error),
              tooltip: 'Obriši',
              onPressed: () => _confirmDelete(context, d, provider),
            ),
        ],
      )),
    ]);
  }

  Widget _buildPagination(DeceasedProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed:
              provider.currentPage > 1 ? () => provider.previousPage() : null,
        ),
        Text(
          'Stranica ${provider.currentPage} od ${provider.totalPages} — Ukupno: ${provider.totalCount} zapisa',
          style: AppTextStyles.caption,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: provider.currentPage < provider.totalPages
              ? () => provider.nextPage()
              : null,
        ),
      ],
    );
  }

  Future<void> _openDetails(
    BuildContext context,
    DeceasedModel deceased,
    DeceasedProvider provider,
  ) async {
    setState(() => _isNavigating = true);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: DeceasedDetailsScreen(deceased: deceased),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _isNavigating = false);
  }

  Future<void> _openForm(BuildContext context, DeceasedModel? deceased) async {
    setState(() => _isNavigating = true);
    context.read<DeceasedProvider>().clearError();

    final result = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<DeceasedProvider>(),
          child: DeceasedFormScreen(deceased: deceased),
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _isNavigating = false);
    context.read<DeceasedProvider>().clearError();

    if (result == 'created') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Preminuli je uspješno registrovan.'),
        backgroundColor: AppColors.success,
      ));
    } else if (result == 'updated') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Zapis je uspješno ažuriran.'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DeceasedModel deceased,
    DeceasedProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši zapis'),
        content: Text(
          'Da li ste sigurni da želite obrisati zapis za ${deceased.fullName}?\n'
          'Svi povezani podaci uključujući smrtovnicu i termine će biti obrisani.',
        ),
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
      final success = await provider.delete(deceased.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Zapis je uspješno obrisan.'
              : (provider.errorMessage ?? 'Greška pri brisanju.')),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ));
      }
    }
  }
}
