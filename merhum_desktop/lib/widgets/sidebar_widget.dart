import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../utils/constants.dart';

class SidebarItem {
  final String label;
  final IconData icon;
  const SidebarItem(this.label, this.icon);
}

const _items = [
  SidebarItem('Kontrolna tabla', Icons.dashboard),
  SidebarItem('Preminuli', Icons.people),
  SidebarItem('Smrtovnice', Icons.article),
  SidebarItem('Termini', Icons.calendar_today),
  SidebarItem('Mesdžidi', Icons.mosque),
  SidebarItem('Groblja', Icons.landscape),
  SidebarItem('Mezarska mjesta', Icons.map),
  SidebarItem('Imami', Icons.person),
  SidebarItem('Pogrebna preduzeća', Icons.business),
  SidebarItem('Nalozi za usluge', Icons.shopping_cart),
  SidebarItem('Izvještaji', Icons.bar_chart),
  SidebarItem('Šifarnici', Icons.settings),
  SidebarItem('Korisnici', Icons.manage_accounts),
  SidebarItem('Predviđanja', Icons.insights),
];

class SidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const SidebarWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Container(
      width: 250,
      color: AppColors.primary,
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Text(
            'Merhum',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final isActive = index == selectedIndex;
                final contentColor =
                    isActive ? Colors.white : Colors.white.withOpacity(0.65);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.secondary.withOpacity(0.35)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isActive
                        ? const Border(
                            left: BorderSide(color: Colors.white, width: 3))
                        : null,
                  ),
                  child: ListTile(
                    leading: Icon(item.icon, color: contentColor, size: 20),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: contentColor,
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    onTap: () => onItemSelected(index),
                  ),
                );
              },
            ),
          ),
          const Divider(color: Colors.white24),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.firstName ?? 'Korisnik',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        auth.role ?? '',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.logout, color: Colors.white70, size: 18),
                  tooltip: 'Odjava',
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const LoginScreen(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                        (_) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
