import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/cemetery_provider.dart';
import '../providers/deceased_provider.dart';
import '../providers/funeral_home_provider.dart';
import '../providers/grave_site_provider.dart';
import '../providers/imam_provider.dart';
import '../providers/obituary_provider.dart';
import '../providers/prediction_provider.dart';
import '../providers/reference_provider.dart';
import '../providers/report_provider.dart';
import '../providers/service_order_provider.dart';
import '../providers/user_provider.dart';
import '../screens/appointments/appointments_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/cemeteries/cemeteries_screen.dart';
import '../screens/deceased/deceased_screen.dart';
import '../screens/funeral_homes/funeral_homes_screen.dart';
import '../screens/grave_sites/grave_sites_screen.dart';
import '../screens/imams/imams_screen.dart';
import '../screens/mosques/mosques_screen.dart';
import '../screens/obituaries/obituaries_screen.dart';
import '../screens/predictions/predictions_screen.dart';
import '../screens/reference_data/reference_data_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/service_orders/service_orders_screen.dart';
import '../screens/users/users_screen.dart';

void navigateByIndex(BuildContext context, int index) {
  Widget screen;
  switch (index) {
    case 0:
      screen = const DashboardScreen();
      break;
    case 1:
      screen = ChangeNotifierProvider.value(
        value: context.read<DeceasedProvider>(),
        child: const DeceasedScreen(),
      );
      break;
    case 2:
      screen = ChangeNotifierProvider.value(
        value: context.read<ObituaryProvider>(),
        child: const ObituariesScreen(),
      );
      break;
    case 3:
      screen = ChangeNotifierProvider.value(
        value: context.read<AppointmentProvider>(),
        child: const AppointmentsScreen(),
      );
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
    case 7:
      screen = ChangeNotifierProvider.value(
        value: context.read<ImamProvider>(),
        child: const ImamsScreen(),
      );
      break;
    case 8:
      screen = ChangeNotifierProvider.value(
        value: context.read<FuneralHomeProvider>(),
        child: const FuneralHomesScreen(),
      );
      break;
    case 9:
      screen = ChangeNotifierProvider.value(
        value: context.read<ServiceOrderProvider>(),
        child: const ServiceOrdersScreen(),
      );
      break;
    case 10:
      screen = ChangeNotifierProvider.value(
        value: context.read<ReportProvider>(),
        child: const ReportsScreen(),
      );
      break;
    case 11:
      screen = ChangeNotifierProvider.value(
        value: context.read<ReferenceProvider>(),
        child: const ReferenceDataScreen(),
      );
      break;
    case 12:
      screen = ChangeNotifierProvider.value(
        value: context.read<UserProvider>(),
        child: const UsersScreen(),
      );
      break;
    case 13:
      screen = ChangeNotifierProvider.value(
        value: context.read<PredictionProvider>(),
        child: const PredictionsScreen(),
      );
      break;
    default:
      return;
  }

  // Keep _RootRouter (route 0) in the stack so it can react to auth changes.
  Navigator.pushAndRemoveUntil(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => screen,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ),
    (route) => route.isFirst,
  );
}
