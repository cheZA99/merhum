import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../models/grave_site_model.dart';
import '../../navigation/app_navigation.dart';
import '../../providers/cemetery_provider.dart';
import '../../providers/grave_site_provider.dart';
import '../../utils/constants.dart';
import '../../utils/status_helper.dart';
import '../../widgets/cemetery_map_widget.dart';
import '../../widgets/sidebar_widget.dart';
import 'grave_site_form_screen.dart';

class GraveSitesScreen extends StatefulWidget {
  final int? initialCemeteryId;
  final String? initialCemeteryName;

  const GraveSitesScreen({
    super.key,
    this.initialCemeteryId,
    this.initialCemeteryName,
  });

  @override
  State<GraveSitesScreen> createState() => _GraveSitesScreenState();
}

class _GraveSitesScreenState extends State<GraveSitesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GraveSiteProvider>();
      context.read<CemeteryProvider>().loadAll();

      if (widget.initialCemeteryId != null) {
        provider.filterCemeteryId = widget.initialCemeteryId;
        provider.loadAll();
        provider.loadMapData(widget.initialCemeteryId!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarWidget(
            selectedIndex: 6,
            onItemSelected: (i) => navigateByIndex(context, i),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<GraveSiteProvider>(
      builder: (context, provider, _) {
        final title = widget.initialCemeteryName != null
            ? 'Mezarska mjesta - ${widget.initialCemeteryName}'
            : 'Mezarska mjesta';

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(provider, title),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(icon: Icon(Icons.list), text: 'Lista'),
                  Tab(icon: Icon(Icons.map), text: 'Mapa groblja'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildListTab(provider),
                    _buildMapTab(provider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(GraveSiteProvider provider, String title) {
    final cemeteries = context.watch<CemeteryProvider>().cemeteries;

    // filterStatus holds an API value (Available/Occupied/Reserved) or null
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.heading1),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<int?>(
                value: provider.filterCemeteryId,
                decoration: const InputDecoration(
                  labelText: 'Groblje',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null, child: Text('Odaberite groblje')),
                  ...cemeteries.map((g) => DropdownMenuItem<int?>(
                        value: g.id,
                        child: Text(g.name),
                      )),
                ],
                onChanged: (v) => provider.setFilterCemetery(v),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String?>(
                value: provider.filterStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Svi')),
                  // Items use API values but display localised labels
                  ...GraveSiteStatus.apiValues.map((apiVal) =>
                      DropdownMenuItem<String?>(
                        value: apiVal,
                        child: Text(GraveSiteStatus.display(apiVal)),
                      )),
                ],
                onChanged: (v) => provider.setFilterStatus(v),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: provider.filterCemeteryId == null
                  ? null
                  : () => _openForm(context, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Dodaj mezarsko mjesto'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildListTab(GraveSiteProvider provider) {
    if (provider.filterCemeteryId == null) {
      return const Center(
        child: Text('Odaberite groblje za prikaz mezarskih mjesta.',
            style: AppTextStyles.body),
      );
    }
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.sites.isEmpty && provider.errorMessage != null && !_isNavigating) {
      // only show the error when the list is empty
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.errorMessage!,
                style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => provider.loadAll(),
              child: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      );
    }
    if (provider.sites.isEmpty) {
      return const Center(
          child: Text('Nema pronađenih mezarskih mjesta.', style: AppTextStyles.body));
    }

    return Column(
      children: [
        // inline error banner, hidden during navigation
        if (provider.errorMessage != null && !_isNavigating)
          Container(
            width: double.infinity,
            color: AppColors.error.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(provider.errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
        Expanded(child: _buildTable(provider)),
        const SizedBox(height: 12),
        _buildPagination(provider),
      ],
    );
  }

  Widget _buildTable(GraveSiteProvider provider) {
    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.background),
          columns: const [
            DataColumn(label: Text('Broj mjesta')),
            DataColumn(label: Text('Red')),
            DataColumn(label: Text('Sektor')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Preminuli')),
            DataColumn(label: Text('QR')),
            DataColumn(label: Text('Akcije')),
          ],
          rows: provider.sites.map((m) => _buildRow(m, provider)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(GraveSiteModel m, GraveSiteProvider provider) {
    return DataRow(cells: [
      DataCell(Text(m.plotNumber, style: AppTextStyles.body)),
      DataCell(Text(m.row?.toString() ?? '-', style: AppTextStyles.body)),
      DataCell(Text(m.sectorName ?? '-', style: AppTextStyles.body)),
      DataCell(_statusChip(m.status)),
      DataCell(Text(m.deceasedName ?? '-', style: AppTextStyles.body)),
      DataCell(m.qrCodeUrl != null && m.qrCodeUrl!.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.qr_code, size: 18,
                  color: AppColors.primary),
              tooltip: 'Prikaži QR kod',
              onPressed: () => _showQrDialog(m),
            )
          : const Text('-', style: AppTextStyles.body)),
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

  Widget _statusChip(String apiStatus) {
    final color = GraveSiteStatus.color(apiStatus);
    final label = GraveSiteStatus.display(apiStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  Widget _buildPagination(GraveSiteProvider provider) {
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

  Widget _buildMapTab(GraveSiteProvider provider) {
    if (provider.filterCemeteryId == null) {
      return const Center(
        child: Text('Odaberite groblje za prikaz mape.',
            style: AppTextStyles.body),
      );
    }
    if (provider.isLoadingMap) {
      return const Center(child: CircularProgressIndicator());
    }

    final cemetery = context
        .read<CemeteryProvider>()
        .cemeteries
        .where((g) => g.id == provider.filterCemeteryId)
        .firstOrNull;

    return CemeteryMapWidget(
      cemetery: cemetery,
      sites: provider.mapData,
      onMarkerTap: (m) => _openForm(context, m),
    );
  }

  void _showQrDialog(GraveSiteModel m) {
    // Backend returns a relative path (/qrcodes/...), build the full URL here
    final qrUrl = m.qrCodeUrl != null
        ? '${apiBaseUrl.replaceAll(RegExp(r'/$'), '')}${m.qrCodeUrl}'
        : null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('QR kod - Mezarsko mjesto ${m.plotNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (qrUrl != null)
              Image.network(
                qrUrl,
                width: 220,
                height: 220,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        width: 220,
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                errorBuilder: (_, __, ___) => const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image, size: 60, color: AppColors.textLight),
                    SizedBox(height: 8),
                    Text('QR kod nije dostupan.', style: AppTextStyles.caption),
                  ],
                ),
              )
            else
              const Icon(Icons.qr_code_2, size: 80, color: AppColors.textLight),
            const SizedBox(height: 12),
            const Text(
              'Skenirajte za pristup profilu preminulog.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
            if (qrUrl != null) ...[
              const SizedBox(height: 4),
              SelectableText(
                qrUrl,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Zatvori'),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context,
      GraveSiteModel? site) async {
    // hide the error during navigation so the list doesn't flash red
    setState(() => _isNavigating = true);
    context.read<GraveSiteProvider>().clearError();

    final result = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(
                value: context.read<CemeteryProvider>()),
            ChangeNotifierProvider.value(
                value: context.read<GraveSiteProvider>()),
          ],
          child: GraveSiteFormScreen(
            site: site,
            initialCemeteryId: site?.cemeteryId ?? widget.initialCemeteryId,
          ),
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _isNavigating = false);
    context.read<GraveSiteProvider>().clearError();

    if (result == 'created') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mezarsko mjesto je uspješno dodano.'),
        backgroundColor: AppColors.success,
      ));
    } else if (result == 'updated') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mezarsko mjesto je uspješno ažurirano.'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  Future<void> _confirmDelete(BuildContext context, GraveSiteModel m,
      GraveSiteProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrdi brisanje'),
        content: Text(
            'Da li ste sigurni da želite obrisati mezarsko mjesto "${m.plotNumber}"?'),
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
              ? 'Mezarsko mjesto je uspješno obrisano.'
              : (provider.errorMessage ?? 'Greška pri brisanju.')),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ));
      }
    }
  }
}
