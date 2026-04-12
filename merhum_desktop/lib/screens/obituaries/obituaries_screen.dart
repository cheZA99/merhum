import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/obituary_model.dart';
import '../../navigation/app_navigation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/obituary_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/sidebar_widget.dart';
import 'obituary_details_screen.dart';
import 'obituary_form_screen.dart';

class ObituariesScreen extends StatefulWidget {
  const ObituariesScreen({super.key});

  @override
  State<ObituariesScreen> createState() => _ObituariesScreenState();
}

class _ObituariesScreenState extends State<ObituariesScreen> {
  bool? _filterIsPublic;
  bool? _filterIsActive;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObituaryProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarWidget(
            selectedIndex: 2,
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
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 16),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text('Smrtovnice', style: AppTextStyles.heading1),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _openForm,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nova smrtovnica'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              labelText: 'Pretraži po imenu preminulog',
              prefixIcon: Icon(Icons.search, size: 18),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            onChanged: (v) {
              context.read<ObituaryProvider>().filterDeceasedName =
                  v.trim().isEmpty ? null : v.trim();
              context.read<ObituaryProvider>().currentPage = 1;
              context.read<ObituaryProvider>().loadAll();
            },
          ),
        ),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<bool?>(
            value: _filterIsPublic,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Vidljivost',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Sve')),
              DropdownMenuItem(value: true, child: Text('Javne')),
              DropdownMenuItem(value: false, child: Text('Privatne')),
            ],
            onChanged: (v) {
              setState(() => _filterIsPublic = v);
              final p = context.read<ObituaryProvider>();
              p.filterIsPublic = v;
              p.currentPage = 1;
              p.loadAll();
            },
          ),
        ),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<bool?>(
            value: _filterIsActive,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Sve')),
              DropdownMenuItem(value: true, child: Text('Aktivne')),
              DropdownMenuItem(value: false, child: Text('Neaktivne')),
            ],
            onChanged: (v) {
              setState(() => _filterIsActive = v);
              final p = context.read<ObituaryProvider>();
              p.filterIsActive = v;
              p.currentPage = 1;
              p.loadAll();
            },
          ),
        ),
        OutlinedButton(
          onPressed: _resetFilters,
          child: const Text('Poništi filtere'),
        ),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _filterIsPublic = null;
      _filterIsActive = null;
      _searchCtrl.clear();
    });
    context.read<ObituaryProvider>().resetFilters();
  }

  Widget _buildBody() {
    return Consumer<ObituaryProvider>(
      builder: (context, p, _) {
        if (p.isLoading) return const Center(child: CircularProgressIndicator());
        if (p.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(p.errorMessage!, style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: p.loadAll, child: const Text('Pokušaj ponovo')),
              ],
            ),
          );
        }
        if (p.obituaries.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article, size: 64, color: AppColors.textLight),
                SizedBox(height: 16),
                Text('Nema pronađenih smrtovnica', style: AppTextStyles.body),
              ],
            ),
          );
        }
        return Column(
          children: [
            Expanded(child: _buildTable(p)),
            _buildSummary(p),
            _buildPagination(p),
          ],
        );
      },
    );
  }

  Widget _buildTable(ObituaryProvider p) {
    return Card(
      child: SingleChildScrollView(
        child: Table(
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade200),
          ),
          columnWidths: const {
            0: FlexColumnWidth(2.5),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.2),
            3: FlexColumnWidth(1.2),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1),
            6: FlexColumnWidth(1.5),
            7: FixedColumnWidth(120),
          },
          children: [
            _tableHeader(),
            ...p.obituaries.map(_tableRow),
          ],
        ),
      ),
    );
  }

  TableRow _tableHeader() {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade100),
      children: [
        _headerCell('Preminuli', style),
        _headerCell('Datum smrti', style),
        _headerCell('Vidljivost', style),
        _headerCell('Status', style),
        _headerCell('Pregledi', style),
        _headerCell('Saučešća', style),
        _headerCell('Datum kreiranja', style),
        _headerCell('Akcije', style),
      ],
    );
  }

  Widget _headerCell(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(text, style: style),
    );
  }

  TableRow _tableRow(ObituaryModel o) {
    final auth = context.read<AuthProvider>();
    final isAdmin = auth.role == 'Administrator';

    return TableRow(
      children: [
        _cell(o.deceasedFullName),
        _cell(o.deceasedDateOfDeath != null ? o.deceasedDateOfDeath! : '—'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: _boolChip(o.isPublic, trueLabel: 'Javna', falseLabel: 'Privatna'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: _boolChip(o.isActive, trueLabel: 'Aktivna', falseLabel: 'Neaktivna',
              falseColor: Colors.grey),
        ),
        _cell(o.viewCount.toString()),
        _cell('${o.approvedCondolenceCount}/${o.condolenceCount}'),
        _cell(DateFormat('dd.MM.yyyy').format(o.createdAt.toLocal())),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 18),
                tooltip: 'Detalji',
                onPressed: () => _openDetails(o),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: 'Uredi',
                onPressed: () => _openEditDialog(o),
              ),
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                  tooltip: 'Obriši',
                  onPressed: () => _confirmDelete(o),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(String text, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(text, style: style ?? AppTextStyles.body),
    );
  }

  Widget _boolChip(bool value,
      {required String trueLabel,
      required String falseLabel,
      Color trueColor = Colors.green,
      Color? falseColor}) {
    final color = value ? trueColor : (falseColor ?? AppColors.error);
    final label = value ? trueLabel : falseLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSummary(ObituaryProvider p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        'Ukupno smrtovnica: ${p.totalCount}',
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPagination(ObituaryProvider p) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: p.currentPage > 1 ? p.previousPage : null,
          ),
          Text('Stranica ${p.currentPage} od ${p.totalPages}'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: p.currentPage < p.totalPages ? p.nextPage : null,
          ),
        ],
      ),
    );
  }

  void _openForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<ObituaryProvider>(),
          child: const ObituaryFormScreen(),
        ),
      ),
    );
  }

  void _openEditDialog(ObituaryModel o) {
    showDialog(
      context: context,
      builder: (_) => _EditObituaryDialog(
        obituary: o,
        onSave: (isPublic, isActive) async {
          final ok = await context
              .read<ObituaryProvider>()
              .update(o.id, isPublic: isPublic, isActive: isActive);
          if (ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Smrtovnica ažurirana.'),
                  backgroundColor: AppColors.success),
            );
          }
        },
      ),
    );
  }

  void _openDetails(ObituaryModel o) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<ObituaryProvider>(),
          child: ObituaryDetailsScreen(obituaryId: o.id),
        ),
      ),
    );
  }

  void _confirmDelete(ObituaryModel o) {
    ConfirmationDialog.show(
      context,
      title: 'Brisanje smrtovnice',
      content: 'Jeste li sigurni da želite obrisati smrtovnicu za ${o.deceasedFullName}?',
      onConfirm: () async {
        final ok = await context.read<ObituaryProvider>().delete(o.id);
        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Smrtovnica obrisana.'),
                backgroundColor: AppColors.success),
          );
        }
      },
    );
  }
}

class _EditObituaryDialog extends StatefulWidget {
  final ObituaryModel obituary;
  final Future<void> Function(bool isPublic, bool isActive) onSave;

  const _EditObituaryDialog({required this.obituary, required this.onSave});

  @override
  State<_EditObituaryDialog> createState() => _EditObituaryDialogState();
}

class _EditObituaryDialogState extends State<_EditObituaryDialog> {
  late bool _isPublic;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isPublic = widget.obituary.isPublic;
    _isActive = widget.obituary.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Uredi smrtovnicu — ${widget.obituary.deceasedFullName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Javna smrtovnica'),
            subtitle: const Text('Vidljiva svima bez prijave'),
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
          ),
          SwitchListTile(
            title: const Text('Aktivna'),
            subtitle: const Text('Dostupna putem linka'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.onSave(_isPublic, _isActive);
                  if (mounted) Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Sačuvaj'),
        ),
      ],
    );
  }
}
