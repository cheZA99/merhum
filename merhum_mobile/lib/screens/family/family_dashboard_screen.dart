import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/deceased_provider.dart';
import '../../models/procedure_status_model.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/bottom_nav_widget.dart';
import '../profile/profile_screen.dart';
import '../public/qr_scanner_screen.dart';
import 'chat_screen.dart';
import 'create_obituary_screen.dart';
import 'my_procedures_screen.dart';
import 'procedure_status_screen.dart';
import 'register_deceased_screen.dart';

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeceasedProvider>().loadMyDeceased();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildPage(),
      bottomNavigationBar: BottomNavWidget(
        currentIndex: _navIndex,
        role: NavRole.family,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }

  Widget _buildPage() {
    switch (_navIndex) {
      case 1:
        return const MyProceduresScreen();
      case 2:
        return const ChatScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHome();
    }
  }

  Widget _buildHome() {
    final auth = context.watch<AuthProvider>();
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<DeceasedProvider>().loadMyDeceased(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dobrodošli,', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    auth.fullName.isEmpty ? 'Korisniče' : auth.fullName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _ActionCard(
                    label: 'Prijavi preminulog',
                    icon: Icons.person_add_alt_1,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterDeceasedScreen()),
                    ),
                  ),
                  _ActionCard(
                    label: 'Moje procedure',
                    icon: Icons.folder_open,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyProceduresScreen()),
                    ),
                  ),
                  _ActionCard(
                    label: 'Skeniraj QR',
                    icon: Icons.qr_code_scanner,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                    ),
                  ),
                  _ActionCard(
                    label: 'Kreiraj smrtovnicu',
                    icon: Icons.article_outlined,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreateObituaryScreen()),
                    ),
                  ),
                  _ActionCard(
                    label: 'Pitaj asistenta',
                    icon: Icons.chat_bubble_outline,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Aktivne procedure', style: AppTextStyles.heading2),
            ),
            const SizedBox(height: 8),
            _buildActiveProcedures(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveProcedures() {
    return Consumer<DeceasedProvider>(builder: (_, p, __) {
      if (p.isLoading && p.myDeceased.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      }
      if (p.myDeceased.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('Nemate aktivnih procedura.', style: AppTextStyles.bodyMedium),
              ),
            ),
          ),
        );
      }
      return Column(
        children: p.myDeceased.map((d) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(d.fullName, style: AppTextStyles.heading3),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        d.procedureStatusName != null
                            ? ProcedureStatusModel.labelFor(d.procedureStatusName!)
                            : 'Status nepoznat',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    Text('${d.cityName ?? ''} • ${DateFormatter.date(d.dateOfDeath)}', style: AppTextStyles.caption),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProcedureStatusScreen(deceasedId: d.id)),
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionCard({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(label, style: AppTextStyles.captionBold, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
