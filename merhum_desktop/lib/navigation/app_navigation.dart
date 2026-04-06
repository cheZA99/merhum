import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cemetery_provider.dart';
import '../providers/grave_site_provider.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/cemeteries/cemeteries_screen.dart';
import '../screens/grave_sites/grave_sites_screen.dart';
import '../screens/mosques/mosques_screen.dart';

// Add new screens here as they are implemented
void navigateByIndex(BuildContext context, int index) {
  Widget screen;
  switch (index) {
    case 0:
      screen = const DashboardScreen();
      break;
    case 4:
      screen = const MosquesScreen();
      break;
    case 5:
      screen = MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<CemeteryProvider>()),
          ChangeNotifierProvider.value(
              value: context.read<GraveSiteProvider>()),
        ],
        child: const CemeteriesScreen(),
      );
      break;
    case 6:
      screen = MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<CemeteryProvider>()),
          ChangeNotifierProvider.value(
              value: context.read<GraveSiteProvider>()),
        ],
        child: const GraveSitesScreen(),
      );
      break;
    default:
      return;
  }

  Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => screen,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ),
  );
}
