import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/appointment_model.dart';
import '../../navigation/app_navigation.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/sidebar_widget.dart';
import 'appointment_form_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  final int? deceasedId;
  final String? deceasedName;

  const AppointmentsScreen({super.key, this.deceasedId, this.deceasedName});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String? _selectedStatus;
  int? _selectedMosqueId;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  static const _dateFormat = 'dd.MM.yyyy HH:mm';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AppointmentProvider>();
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
            selectedIndex: 3,
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
        ? 'Termini - ${widget.deceasedName}'
        : 'Termini';
    return Row(
      children: [
        Text(title, style: AppTextStyles.heading1),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _openForm,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Zakažite termin'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Consumer<AppointmentProvider>(
      builder: (context, p, _) {
        return Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _dateButton('Od', _dateFrom, (d) {
              setState(() => _dateFrom = d);
              _applyFilters();
            }),
            _dateButton('Do', _dateTo, (d) {
              setState(() => _dateTo = d);
              _applyFilters();
            }),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<int?>(
                value: _selectedMosqueId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Džamija',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Sve džamije')),
                  ...p.mosques.map((m) => DropdownMenuItem(
                        value: m['id'] as int,
                        child: Text(m['name'] as String? ?? ''),
                      )),
                ],
                onChanged: (v) {
                  setState(() => _selectedMosqueId = v);
                  _applyFilters();
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
                  DropdownMenuItem(value: 'Scheduled', child: Text('Zakazano')),
                  DropdownMenuItem(value: 'Held', child: Text('Održano')),
                  DropdownMenuItem(value: 'Cancelled', child: Text('Otkazano')),
                ],
                onChanged: (v) {
                  setState(() => _selectedStatus = v);
                  _applyFilters();
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

  void _applyFilters() {
    context.read<AppointmentProvider>().setFilter(
          mosqueId: _selectedMosqueId,
          status: _selectedStatus,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
        );
  }

  void _resetFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedMosqueId = null;
      _dateFrom = null;
      _dateTo = null;
    });
    context.read<AppointmentProvider>().resetFilters();
  }

  Widget _buildBody() {
    return Consumer<AppointmentProvider>(
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
        if (p.appointments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: AppColors.textLight),
                SizedBox(height: 16),
                Text('Nema pronađenih termina', style: AppTextStyles.body),
              ],
            ),
          );
        }
        return Column(
          children: [
            Expanded(child: _buildTable(p)),
            _buildPagination(p),
          ],
        );
      },
    );
  }

  Widget _buildTable(AppointmentProvider p) {
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
            3: FlexColumnWidth(2),
            4: FlexColumnWidth(2),
            5: FlexColumnWidth(1.5),
            6: FlexColumnWidth(1.2),
            7: FixedColumnWidth(100),
          },
          children: [
            _tableHeader(),
            ...p.appointments.map(_tableRow),
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
        _headerCell('Džamija', style),
        _headerCell('Groblje', style),
        _headerCell('Imam', style),
        _headerCell('Datum i vrijeme', style),
        _headerCell('Mezarsko mjesto', style),
        _headerCell('Status', style),
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

  TableRow _tableRow(AppointmentModel a) {
    final auth = context.read<AuthProvider>();
    final isAdmin = auth.role == 'Administrator';

    return TableRow(
      children: [
        _cell(a.deceasedFullName),
        _cell(a.mosqueName),
        _cell(a.cemeteryName),
        _cell(
          a.imamFullName ?? 'Nije dodijeljen',
          style: a.imamFullName == null
              ? const TextStyle(color: AppColors.textLight, fontStyle: FontStyle.italic, fontSize: 13)
              : null,
        ),
        _cell(DateFormat(_dateFormat).format(a.funeralDateTime.toLocal())),
        _cell(
          a.gravePlotNumber ?? 'Nije dodijeljeno',
          style: a.gravePlotNumber == null
              ? const TextStyle(color: AppColors.textLight, fontStyle: FontStyle.italic, fontSize: 13)
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: _statusChip(a.status),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: 'Uredi',
                onPressed: () => _openForm(appointment: a),
              ),
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                  tooltip: 'Obriši',
                  onPressed: () => _confirmDelete(a),
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
      case 'Scheduled':
        color = Colors.blue;
        label = 'Zakazano';
        break;
      case 'Held':
        color = Colors.green;
        label = 'Održano';
        break;
      case 'Cancelled':
        color = AppColors.error;
        label = 'Otkazano';
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

  Widget _buildPagination(AppointmentProvider p) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: p.currentPage > 1 ? p.previousPage : null,
          ),
          Text('Stranica ${p.currentPage} od ${p.totalPages}  (${p.totalCount} ukupno)'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: p.currentPage < p.totalPages ? p.nextPage : null,
          ),
        ],
      ),
    );
  }

  void _openForm({AppointmentModel? appointment}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<AppointmentProvider>(),
          child: AppointmentFormScreen(
            appointment: appointment,
            preselectedDeceasedId: widget.deceasedId,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(AppointmentModel a) {
    final date = DateFormat(_dateFormat).format(a.funeralDateTime.toLocal());
    ConfirmationDialog.show(
      context,
      title: 'Otkazivanje termina',
      content: 'Jeste li sigurni da želite otkazati termin za ${a.deceasedFullName} zakazan za $date?',
      onConfirm: () async {
        final ok = await context.read<AppointmentProvider>().delete(a.id);
        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Termin obrisan.'), backgroundColor: AppColors.success),
          );
        }
      },
    );
  }
}
