import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/obituary_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/obituary_card_widget.dart';
import '../../widgets/funeral_card_widget.dart';
import '../../widgets/bottom_nav_widget.dart';
import '../auth/login_screen.dart';
import '../family/family_dashboard_screen.dart';
import '../profile/profile_screen.dart';
import 'obituary_search_screen.dart';
import 'obituary_detail_screen.dart';
import 'upcoming_funerals_screen.dart';
import 'qr_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ObituaryProvider>();
      p.loadRecent();
      p.loadUpcomingFunerals();
    });
  }

  Widget _buildPage() {
    switch (_navIndex) {
      case 1:
        return const ObituarySearchScreen();
      case 2:
        return const UpcomingFuneralsScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHome();
    }
  }

  Widget _buildHome() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await context.read<ObituaryProvider>().loadRecent();
        await context.read<ObituaryProvider>().loadUpcomingFunerals();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildRecentObituaries(),
            const SizedBox(height: 24),
            _buildUpcomingFunerals(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mosque, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              const Text('Merhum', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Digitalna koordinacija dženaze', style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ObituarySearchScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.textLight),
              const SizedBox(width: 10),
              const Text('Pretraži smrtovnice...', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final auth = context.watch<AuthProvider>();
    final actions = [
      _QuickAction('Pretraži smrtovnice', Icons.search, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ObituarySearchScreen()))),
      _QuickAction('Nadolazeće dženaze', Icons.calendar_today, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpcomingFuneralsScreen()))),
      _QuickAction('Skeniraj QR', Icons.qr_code_scanner, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QrScannerScreen()))),
      auth.isLoggedIn
          ? _QuickAction('Moje procedure', Icons.folder, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FamilyDashboardScreen())))
          : _QuickAction('Prijavi se', Icons.login, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()))),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: actions.map((a) => _QuickActionCard(action: a)).toList(),
      ),
    );
  }

  Widget _buildRecentObituaries() {
    return Consumer<ObituaryProvider>(builder: (_, p, __) {
      if (p.recent.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nedavne smrtovnice', style: AppTextStyles.heading2),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ObituarySearchScreen())),
                  child: const Text('Pogledaj sve \u2192', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: p.recent.length,
              itemBuilder: (_, i) {
                final o = p.recent[i];
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ObituaryDetailScreen(slug: o.uniqueSlug))),
                  child: Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.deceasedFullName, style: AppTextStyles.heading3, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const Spacer(),
                        Text(o.cityName ?? '', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildUpcomingFunerals() {
    return Consumer<ObituaryProvider>(builder: (_, p, __) {
      final items = p.upcomingFunerals.take(3).toList();
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nadolazeće dženaze', style: AppTextStyles.heading2),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpcomingFuneralsScreen())),
                  child: const Text('Pogledaj sve \u2192', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ),
          ...items.map((f) => FuneralCardWidget(data: f)),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildPage(),
      bottomNavigationBar: BottomNavWidget(
        currentIndex: _navIndex,
        role: NavRole.publicUser,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  _QuickAction(this.label, this.icon, this.onTap);
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, size: 32, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(action.label, style: AppTextStyles.captionBold, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
