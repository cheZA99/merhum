import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/auth_provider.dart';
import 'providers/cemetery_provider.dart';
import 'providers/deceased_provider.dart';
import 'providers/funeral_home_provider.dart';
import 'providers/grave_site_provider.dart';
import 'providers/imam_provider.dart';
import 'providers/mosque_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/obituary_provider.dart';
import 'providers/reference_provider.dart';
import 'providers/report_provider.dart';
import 'providers/service_order_provider.dart';
import 'providers/user_provider.dart';
import 'services/appointment_service.dart';
import 'services/obituary_service.dart';
import 'services/report_service.dart';
import 'services/service_order_service.dart';
import 'services/user_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/cemetery_service.dart';
import 'services/deceased_service.dart';
import 'services/funeral_home_service.dart';
import 'services/grave_site_service.dart';
import 'services/imam_service.dart';
import 'services/mosque_service.dart';
import 'services/reference_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  windowManager.waitUntilReadyToShow(
    const WindowOptions(
      minimumSize: Size(1200, 700),
      size: Size(1400, 800),
      center: true,
      title: 'Merhum — Admin panel',
    ),
  );

  // Single instance shared across all providers so the token is read/written from one place
  final authService = AuthService();
  final apiService = ApiService(authService);
  final authProvider = AuthProvider(authService: authService, apiService: apiService)..checkAuthStatus();
  apiService.onUnauthorized = authProvider.forceLogout;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(
          create: (_) => MosqueProvider(MosqueService(apiService)),
        ),
        ChangeNotifierProvider(
          create: (_) => CemeteryProvider(CemeteryService(apiService)),
        ),
        ChangeNotifierProvider(
          create: (_) => GraveSiteProvider(GraveSiteService(apiService)),
        ),
        ChangeNotifierProvider(
          create: (_) => DeceasedProvider(DeceasedService(apiService)),
        ),
        ChangeNotifierProvider(
          create: (_) => ImamProvider(ImamService(apiService)),
        ),
        ChangeNotifierProvider(
          create: (_) => FuneralHomeProvider(FuneralHomeService(apiService)),
        ),
        ChangeNotifierProvider(
          create: (_) => ReferenceProvider(ReferenceService(apiService)),
        ),
        ChangeNotifierProvider(
          create: (_) => AppointmentProvider(AppointmentService(apiService)),
        ),
        ChangeNotifierProvider(
          create: (_) => ServiceOrderProvider(ServiceOrderService(apiService)),
        ),
        ChangeNotifierProvider(
          create: (_) => ObituaryProvider(ObituaryService(apiService)),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportProvider(ReportService(apiService)),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(UserService(apiService)),
        ),
      ],
      child: const MerhumApp(),
    ),
  );
}

class MerhumApp extends StatelessWidget {
  const MerhumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Merhum',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isLoggedIn) {
          // Pop any screens pushed on top of this root route (e.g. after forceLogout on 401).
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final nav = Navigator.of(context);
            if (nav.canPop()) nav.popUntil((r) => r.isFirst);
          });
          return const LoginScreen();
        }
        return const DashboardScreen();
      },
    );
  }
}
