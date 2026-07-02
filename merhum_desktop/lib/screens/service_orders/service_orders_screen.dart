import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/service_order_model.dart';
import '../../navigation/app_navigation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_order_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/sidebar_widget.dart';
import 'service_order_form_screen.dart';

class ServiceOrdersScreen extends StatefulWidget {
  final int? deceasedId;
  final String? deceasedName;

  const ServiceOrdersScreen({super.key, this.deceasedId, this.deceasedName});

  @override
  State<ServiceOrdersScreen> createState() => _ServiceOrdersScreenState();
}

class _ServiceOrdersScreenState extends State<ServiceOrdersScreen> {
  String? _selectedStatus;
  int? _selectedFuneralHomeId;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ServiceOrderProvider>();
      p.deceasedIdContext = widget.deceasedId;
      p.loadDropdownData();
      p.loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarWidget(
            selectedIndex: 9,
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
    final title = widget.deceasedName != null
        ? 'Nalozi za usluge - ${widget.deceasedName}'
        : 'Nalozi za usluge';
    return Row(
      children: [
        Text(title, style: AppTextStyles.heading1),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _openForm,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Dodaj nalog'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Consumer<ServiceOrderProvider>(
      builder: (context, p, _) {
        return Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _dateButton('Od', _dateFrom, (d) {
              setState(() => _dateFrom = d);
              _applyCurrentFilters();
            }),
            _dateButton('Do', _dateTo, (d) {
              setState(() => _dateTo = d);
              _applyCurrentFilters();
            }),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<int?>(
                value: _selectedFuneralHomeId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Pogrebno preduzeće',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Sva pogrebna preduzeća')),
                  ...p.funeralHomes.map((f) => DropdownMenuItem(
                        value: f['id'] as int,
                        child: Text(f['name'] as String? ?? ''),
                      )),
                ],
                onChanged: (v) {
                  setState(() => _selectedFuneralHomeId = v);
                  _applyCurrentFilters();
                },
              ),
            ),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String?>(
                value: _selectedStatus,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Svi')),
                  DropdownMenuItem(value: 'Ordered', child: Text('Naručeno')),
                  DropdownMenuItem(value: 'InProgress', child: Text('U toku')),
                  DropdownMenuItem(value: 'Completed', child: Text('Završeno')),
                ],
                onChanged: (v) {
                  setState(() => _selectedStatus = v);
                  _applyCurrentFilters();
                },
              ),
            ),
            OutlinedButton(
              onPressed: _resetFilters,
              child: const Text('Poništi filtere'),
            ),
          ],
        );
      },
    );
  }

  Widget _dateButton(String label, DateTime? value, ValueChanged<DateTime?> onPicked) {
    final text = value != null ? DateFormat('dd.MM.yyyy').format(value) : label;
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        onPicked(picked);
      },
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text(text),
    );
  }

  void _applyCurrentFilters() {
    final p = context.read<ServiceOrderProvider>();
    p.filterFuneralHomeId = _selectedFuneralHomeId;
    p.filterStatus = _selectedStatus;
    p.filterDateFrom = _dateFrom;
    p.filterDateTo = _dateTo;
    p.currentPage = 1;
    p.loadAll();
  }

  void _resetFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedFuneralHomeId = null;
      _dateFrom = null;
      _dateTo = null;
    });
    context.read<ServiceOrderProvider>().resetFilters();
  }

  Widget _buildBody() {
    return Consumer<ServiceOrderProvider>(
      builder: (context, p, _) {
        if (p.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
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
        if (p.orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart, size: 64, color: AppColors.textLight),
                SizedBox(height: 16),
                Text('Nema pronađenih naloga', style: AppTextStyles.body),
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

  Widget _buildTable(ServiceOrderProvider p) {
    return Card(
      child: SingleChildScrollView(
        child: Table(
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade200),
          ),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(1.2),
            4: FlexColumnWidth(1.2),
            5: FlexColumnWidth(1.5),
            6: FlexColumnWidth(1.5),
            7: FixedColumnWidth(100),
          },
          children: [
            _tableHeader(),
            ...p.orders.map(_tableRow),
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
        _headerCell('Pogrebno preduzeće', style),
        _headerCell('Vrsta usluge', style),
        _headerCell('Cijena', style),
        _headerCell('Status', style),
        _headerCell('Datum narudžbe', style),
        _headerCell('Datum završetka', style),
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

  TableRow _tableRow(ServiceOrderModel o) {
    final auth = context.read<AuthProvider>();
    final isAdmin = auth.role == 'Administrator';

    return TableRow(
      children: [
        _cell(o.deceasedFullName),
        _cell(o.funeralHomeName),
        _cell(o.serviceTypeName),
        _cell('${o.price.toStringAsFixed(2)} KM'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: _statusChip(o.status),
        ),
        _cell(DateFormat('dd.MM.yyyy').format(o.orderedAt.toLocal())),
        _cell(
          o.completedAt != null
              ? DateFormat('dd.MM.yyyy').format(o.completedAt!.toLocal())
              : '-',
          style: o.completedAt == null
              ? const TextStyle(color: AppColors.textLight, fontSize: 13)
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: 'Uredi',
                onPressed: () => _openForm(order: o),
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

  Widget _statusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'Ordered':
        color = Colors.grey;
        label = 'Naručeno';
        break;
      case 'InProgress':
        color = Colors.orange;
        label = 'U toku';
        break;
      case 'Completed':
        color = Colors.green;
        label = 'Završeno';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
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
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSummary(ServiceOrderProvider p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Text(
            'Ukupno naloga: ${p.totalCount}  |  Ukupna vrijednost: ${p.totalValue.toStringAsFixed(2)} KM',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(ServiceOrderProvider p) {
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

  void _openForm({ServiceOrderModel? order}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<ServiceOrderProvider>(),
          child: ServiceOrderFormScreen(
            order: order,
            preselectedDeceasedId: widget.deceasedId,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(ServiceOrderModel o) {
    ConfirmationDialog.show(
      context,
      title: 'Brisanje naloga',
      content: 'Jeste li sigurni da želite obrisati nalog "${o.serviceTypeName}" za ${o.deceasedFullName}?',
      onConfirm: () async {
        final ok = await context.read<ServiceOrderProvider>().delete(o.id);
        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nalog obrisan.'), backgroundColor: AppColors.success),
          );
        }
      },
    );
  }
}
