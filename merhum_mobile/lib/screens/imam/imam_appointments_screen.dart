import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/bottom_nav_widget.dart';
import '../profile/profile_screen.dart';

class ImamAppointmentsScreen extends StatefulWidget {
  const ImamAppointmentsScreen({super.key});

  @override
  State<ImamAppointmentsScreen> createState() => _ImamAppointmentsScreenState();
}

class _ImamAppointmentsScreenState extends State<ImamAppointmentsScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().loadMyAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _navIndex == 0 ? const _AppointmentsTab() : const ProfileScreen(),
      bottomNavigationBar: BottomNavWidget(
        currentIndex: _navIndex,
        role: NavRole.imam,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

class _AppointmentsTab extends StatelessWidget {
  const _AppointmentsTab();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Dženaze'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Nadolazeće'),
              Tab(text: 'Prošle'),
            ],
          ),
        ),
        body: Consumer<AppointmentProvider>(builder: (_, p, __) {
          if (p.isLoading && p.appointments.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final now = DateTime.now();
          final upcoming = p.appointments.where((a) => a.funeralDateTime.isAfter(now)).toList()
            ..sort((a, b) => a.funeralDateTime.compareTo(b.funeralDateTime));
          final past = p.appointments.where((a) => !a.funeralDateTime.isAfter(now)).toList()
            ..sort((a, b) => b.funeralDateTime.compareTo(a.funeralDateTime));
          return TabBarView(
            children: [
              _AppointmentList(items: upcoming, emptyText: 'Nema nadolazećih dženaza.'),
              _AppointmentList(items: past, emptyText: 'Nema prošlih dženaza.'),
            ],
          );
        }),
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final List<AppointmentModel> items;
  final String emptyText;
  const _AppointmentList({required this.items, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<AppointmentProvider>().loadMyAppointments(),
      child: items.isEmpty
          ? ListView(children: [const SizedBox(height: 100), Center(child: Text(emptyText, style: AppTextStyles.bodyMedium))])
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final a = items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showDetails(context, a),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.deceasedFullName, style: AppTextStyles.heading3),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14, color: AppColors.textMedium),
                                const SizedBox(width: 6),
                                Text(DateFormatter.dateTime(a.funeralDateTime), style: AppTextStyles.bodyMedium),
                              ],
                            ),
                            if (a.mosqueName != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.mosque_outlined, size: 14, color: AppColors.textMedium),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(a.mosqueName!, style: AppTextStyles.bodyMedium)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showDetails(BuildContext context, AppointmentModel a) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(a.deceasedFullName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(Icons.calendar_today, DateFormatter.dateTime(a.funeralDateTime)),
            if (a.mosqueName != null) _row(Icons.mosque_outlined, a.mosqueName!),
            if (a.mosqueAddress != null) _row(Icons.location_on_outlined, a.mosqueAddress!),
            if (a.cemeteryName != null) _row(Icons.park_outlined, a.cemeteryName!),
            if (a.graveSiteNumber != null) _row(Icons.numbers, 'Mezar: ${a.graveSiteNumber}'),
            if (a.contactPerson != null) _row(Icons.person_outline, a.contactPerson!),
            if (a.contactPhone != null)
              InkWell(
                onTap: () => launchUrl(Uri.parse('tel:${a.contactPhone}')),
                child: _row(Icons.phone, a.contactPhone!, isLink: true),
              ),
            if (a.notes != null && a.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(a.notes!, style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textMedium)),
            ],
          ],
        ),
        actions: [
          if (a.mosqueLatitude != null && a.mosqueLongitude != null)
            TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse('https://maps.google.com/?q=${a.mosqueLatitude},${a.mosqueLongitude}'),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Mapa'),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Zatvori')),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: isLink
                  ? const TextStyle(color: AppColors.primary, decoration: TextDecoration.underline)
                  : AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
