import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/groblje_provider.dart';
import '../providers/mezarsko_mjesto_provider.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/groblja/groblja_screen.dart';
import '../screens/mezarska_mjesta/mezarska_mjesta_screen.dart';
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
          ChangeNotifierProvider.value(value: context.read<GrobljeProvider>()),
          ChangeNotifierProvider.value(
              value: context.read<MezarskoMjestoProvider>()),
        ],
        child: const GrobljaScreen(),
      );
      break;
    case 6:
      screen = MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<GrobljeProvider>()),
          ChangeNotifierProvider.value(
              value: context.read<MezarskoMjestoProvider>()),
        ],
        child: const MezarskaMjestaScreen(),
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
