import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/deceased_provider.dart';
import '../../providers/service_order_provider.dart';
import '../../models/procedure_status_model.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/status_timeline_widget.dart';
import 'create_obituary_screen.dart';
import 'order_services_screen.dart';
import 'schedule_appointment_screen.dart';

class ProcedureStatusScreen extends StatefulWidget {
  final int deceasedId;
  const ProcedureStatusScreen({super.key, required this.deceasedId});

  @override
  State<ProcedureStatusScreen> createState() => _ProcedureStatusScreenState();
}

class _ProcedureStatusScreenState extends State<ProcedureStatusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeceasedProvider>().loadById(widget.deceasedId);
      context.read<AppointmentProvider>().loadForDeceased(widget.deceasedId);
      context.read<ServiceOrderProvider>().loadForDeceased(widget.deceasedId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DeceasedProvider>();
    final ap = context.watch<AppointmentProvider>();
    final sp = context.watch<ServiceOrderProvider>();

    final d = dp.selected;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(d?.fullName ?? 'Procedura')),
      body: dp.isLoading && d == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : d == null
              ? const Center(child: Text('Nema podataka.'))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await context.read<DeceasedProvider>().loadById(widget.deceasedId);
                    await context.read<AppointmentProvider>().loadForDeceased(widget.deceasedId);
                    await context.read<ServiceOrderProvider>().loadForDeceased(widget.deceasedId);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(d.procedureStatusName ?? '—', d.procedureStatusId ?? 0),
                        const SizedBox(height: 20),
                        const Text('Faze procedure', style: AppTextStyles.heading2),
                        const SizedBox(height: 12),
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: StatusTimelineWidget(
                              currentStatusName: d.procedureStatusName ?? '',
                              history: dp.statusHistory,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildActions(d.procedureStatusId ?? 1),
                        const SizedBox(height: 20),
                        if (ap.selectedAppointment != null) ...[
                          const Text('Termin dženaze', style: AppTextStyles.heading2),
                          const SizedBox(height: 8),
                          _buildAppointmentCard(ap),
                          const SizedBox(height: 20),
                        ],
                        const Text('Narudžbe usluga', style: AppTextStyles.heading2),
                        const SizedBox(height: 8),
                        _buildOrders(sp),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusCard(String statusName, int statusId) {
    final phases = ProcedureStatusModel.phases;
    final idx = phases.indexOf(statusName);
    final percent = idx < 0 ? 0.0 : (idx + 1) / phases.length;
    return Card(
      color: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trenutni status', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            Text(statusName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 6),
            Text('${(percent * 100).round()}% završeno', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(int statusId) {
    final buttons = <Widget>[];
    if (statusId <= 1) {
      buttons.add(_actionBtn('Zakaži termin', Icons.calendar_today, () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ScheduleAppointmentScreen(deceasedId: widget.deceasedId)),
          )));
    }
    if (statusId >= 2 && statusId <= 3) {
      buttons.add(_actionBtn('Naruči usluge', Icons.shopping_bag_outlined, () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OrderServicesScreen(deceasedId: widget.deceasedId)),
          )));
    }
    if (statusId >= 4) {
      buttons.add(_actionBtn('Kreiraj smrtovnicu', Icons.article_outlined, () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateObituaryScreen()),
          )));
    }
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buttons,
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentProvider ap) {
    final a = ap.selectedAppointment!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(DateFormatter.dateTime(a.funeralDateTime), style: AppTextStyles.heading3),
              ],
            ),
            const SizedBox(height: 8),
            if (a.mosqueName != null) Text('Džamija: ${a.mosqueName}', style: AppTextStyles.body),
            if (a.imamName != null) Text('Imam: ${a.imamName}', style: AppTextStyles.body),
            if (a.cemeteryName != null) Text('Groblje: ${a.cemeteryName}', style: AppTextStyles.body),
            if (a.graveSiteNumber != null) Text('Mezar: ${a.graveSiteNumber}', style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }

  Widget _buildOrders(ServiceOrderProvider sp) {
    final orders = sp.orders.where((o) => o.deceasedId == widget.deceasedId).toList();
    if (orders.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Nema narudžbi.', style: AppTextStyles.bodyMedium),
        ),
      );
    }
    return Column(
      children: orders.map((o) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
          title: Text(o.serviceTypeName ?? 'Usluga'),
          subtitle: Text('${o.funeralHomeName ?? ''} • ${DateFormatter.money(o.price)}'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(o.status, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ),
      )).toList(),
    );
  }
}
