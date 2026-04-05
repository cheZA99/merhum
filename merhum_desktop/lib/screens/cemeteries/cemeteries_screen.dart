import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cemetery_model.dart';
import '../../navigation/app_navigation.dart';
import '../../providers/cemetery_provider.dart';
import '../../providers/grave_site_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/sidebar_widget.dart';
import '../grave_sites/grave_sites_screen.dart';
import 'cemetery_form_screen.dart';

class CemeteriesScreen extends StatefulWidget {
  const CemeteriesScreen({super.key});

  @override
  State<CemeteriesScreen> createState() => _CemeteriesScreenState();
}

class _CemeteriesScreenState extends State<CemeteriesScreen> {
  int _currentPage = 0;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<CemeteryProvider>();
      p.loadAll();
      p.loadCities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarWidget(
            selectedIndex: 5,
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
    return Consumer<CemeteryProvider>(
      builder: (context, provider, _) => Row(
        children: [
          const Text('Cemeteries', style: AppTextStyles.heading1),
          const Spacer(),
          SizedBox(
            width: 220,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name...',
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
            value: provider.filterCityId,
            hint: const Text('All cities'),
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem<int?>(
                  value: null, child: Text('All cities')),
              ...provider.cities.map((g) => DropdownMenuItem<int?>(
                    value: g['id'] as int,
                    child: Text(g['name'] as String? ?? ''),
                  )),
            ],
            onChanged: (v) {
              setState(() => _currentPage = 0);
              provider.setFilterCity(v);
            },
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () => _openForm(context, null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add cemetery'),
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<CemeteryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final allItems = provider.cemeteries;

        if (allItems.isEmpty && provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(provider.errorMessage!,
                    style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 12),
                TextButton(
                    onPressed: provider.loadAll,
                    child: const Text('Try again')),
              ],
            ),
          );
        }

        if (allItems.isEmpty) {
          return const Center(
              child: Text('No cemeteries found.', style: AppTextStyles.body));
        }

        final totalPages =
            (allItems.length / _pageSize).ceil().clamp(1, 999);
        final pageItems = allItems
            .skip(_currentPage * _pageSize)
            .take(_pageSize)
            .toList();

        return Column(
          children: [
            if (provider.errorMessage != null)
              Container(
                width: double.infinity,
                color: AppColors.error.withValues(alpha: 0.1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(provider.errorMessage!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 13)),
              ),
            Expanded(child: _buildTable(context, pageItems, provider)),
            const SizedBox(height: 12),
            _buildPagination(allItems.length, totalPages),
          ],
        );
      },
    );
  }

  Widget _buildTable(BuildContext context, List<CemeteryModel> items,
      CemeteryProvider provider) {
    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.background),
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('City')),
            DataColumn(label: Text('Total')),
            DataColumn(label: Text('Occupied')),
            DataColumn(label: Text('Available')),
            DataColumn(label: Text('Occupancy')),
            DataColumn(label: Text('Active')),
            DataColumn(label: Text('Actions')),
          ],
          rows: items.map((g) => _buildRow(context, g, provider)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(
      BuildContext context, CemeteryModel g, CemeteryProvider provider) {
    final percentage = g.occupancyPercentage;
    final progressColor = percentage >= 85
        ? AppColors.error
        : percentage >= 60
            ? Colors.orange
            : AppColors.success;

    return DataRow(cells: [
      DataCell(Text(g.name, style: AppTextStyles.body)),
      DataCell(Text(g.cityName, style: AppTextStyles.body)),
      DataCell(Text(g.totalPlots.toString(), style: AppTextStyles.body)),
      DataCell(Text(g.occupiedPlots.toString(), style: AppTextStyles.body)),
      DataCell(Text(g.availablePlots.toString(), style: AppTextStyles.body)),
      DataCell(SizedBox(
        width: 120,
        child: Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: percentage / 100,
                color: progressColor,
                backgroundColor: progressColor.withValues(alpha: 0.15),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 6),
            Text('${percentage.toStringAsFixed(0)}%',
                style: AppTextStyles.caption),
          ],
        ),
      )),
      DataCell(Icon(
        g.isActive ? Icons.check_circle : Icons.cancel,
        color: g.isActive ? AppColors.success : AppColors.error,
        size: 20,
      )),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            tooltip: 'Edit',
            onPressed: () => _openForm(context, g),
          ),
          IconButton(
            icon: const Icon(Icons.list, size: 18, color: AppColors.primary),
            tooltip: 'Grave sites',
            onPressed: () => _openGraveSites(context, g),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, g, provider),
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
        Text('Page ${_currentPage + 1} of $totalPages  ($total total)',
            style: AppTextStyles.caption),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _currentPage < totalPages - 1
              ? () => setState(() => _currentPage++)
              : null,
        ),
      ],
    );
  }

  Future<void> _openForm(BuildContext context, CemeteryModel? cemetery) async {
    context.read<CemeteryProvider>().clearError();
    final result = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<CemeteryProvider>(),
          child: CemeteryFormScreen(cemetery: cemetery),
        ),
      ),
    );
    if (!mounted) return;
    if (result == 'created') {
      setState(() => _currentPage = 0);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cemetery added successfully.'),
        backgroundColor: AppColors.success,
      ));
    } else if (result == 'updated') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cemetery updated successfully.'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  void _openGraveSites(BuildContext context, CemeteryModel cemetery) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: context.read<CemeteryProvider>()),
            ChangeNotifierProvider.value(
                value: context.read<GraveSiteProvider>()),
          ],
          child: GraveSitesScreen(
            initialCemeteryId: cemetery.id,
            initialCemeteryName: cemetery.name,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CemeteryModel g,
      CemeteryProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm deletion'),
        content: Text(
          'Are you sure you want to delete the cemetery "${g.name}"?\n\n'
          'All grave sites in this cemetery will also be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await provider.delete(g.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Cemetery deleted successfully.'
              : (provider.errorMessage ?? 'Error deleting.')),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ));
      }
    }
  }
}
