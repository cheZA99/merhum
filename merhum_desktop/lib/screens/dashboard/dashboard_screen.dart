import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../navigation/app_navigation.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/deceased_provider.dart';
import '../../providers/grave_site_provider.dart';
import '../../providers/obituary_provider.dart';
import '../../providers/service_order_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/sidebar_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DeceasedProvider>().loadTotalDeceasedCount();
      context.read<AppointmentProvider>().loadActiveCount();
      context.read<GraveSiteProvider>().loadFreeCount();
      context.read<ObituaryProvider>().loadTodayCount();
      context.read<DeceasedProvider>().loadRecentDeceased();
      context.read<AppointmentProvider>().loadUpcoming();
      context.read<ServiceOrderProvider>().loadPending();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarWidget(
            selectedIndex: _selectedIndex,
            onItemSelected: (i) => navigateByIndex(context, i),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final deceasedProvider = context.watch<DeceasedProvider>();
    final appointmentProvider = context.watch<AppointmentProvider>();
    final graveSiteProvider = context.watch<GraveSiteProvider>();
    final obituaryProvider = context.watch<ObituaryProvider>();
    final serviceOrderProvider = context.watch<ServiceOrderProvider>();

    final deceasedCount = deceasedProvider.totalDeceasedCount;
    final activeAppointments = appointmentProvider.activeCount;
    final freeGraveSites = graveSiteProvider.freeCount;
    final todayObituaries = obituaryProvider.todayCount;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kontrolna tabla', style: AppTextStyles.heading1),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Ukupno preminulih',
                  value: '$deceasedCount',
                  icon: Icons.people,
                  color: const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  label: 'Aktivni termini',
                  value: '$activeAppointments',
                  icon: Icons.calendar_today,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  label: 'Slobodna mezarska mjesta',
                  value: '$freeGraveSites',
                  icon: Icons.map,
                  color: const Color(0xFF6A1B9A),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  label: 'Smrtovnice danas',
                  value: '$todayObituaries',
                  icon: Icons.article,
                  color: const Color(0xFFC62828),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DashboardListCard(
                    title: 'Nadolazeći termini',
                    icon: Icons.calendar_today,
                    emptyText: 'Nema zakazanih termina',
                    items: appointmentProvider.upcomingAppointments
                        .map((a) => _ListItem(
                              a.deceasedFullName,
                              DateFormat('dd.MM.yyyy. HH:mm').format(a.funeralDateTime),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DashboardListCard(
                    title: 'Nedavno registrovani preminuli',
                    icon: Icons.people_outline,
                    emptyText: 'Nema registrovanih preminulih',
                    items: deceasedProvider.recentDeceased
                        .map((d) => _ListItem(
                              d.fullName,
                              DateFormat('dd.MM.yyyy').format(d.dateOfDeath),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DashboardListCard(
                    title: 'Nalozi za usluge na čekanju (${serviceOrderProvider.pendingCount})',
                    icon: Icons.pending_actions,
                    emptyText: 'Nema naloga na čekanju',
                    items: serviceOrderProvider.pendingOrders
                        .map((o) => _ListItem(o.deceasedFullName, o.serviceTypeName))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListItem {
  final String primary;
  final String secondary;

  const _ListItem(this.primary, this.secondary);
}

class _DashboardListCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String emptyText;
  final List<_ListItem> items;

  const _DashboardListCard({
    required this.title,
    required this.icon,
    required this.emptyText,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: AppTextStyles.heading2, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const Divider(height: 20),
            if (items.isEmpty)
              Text(emptyText, style: AppTextStyles.caption)
            else
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(item.primary,
                              style: AppTextStyles.body, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Text(item.secondary, style: AppTextStyles.caption),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color)),
                const SizedBox(height: 4),
                Text(label, style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
