import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/auth_provider.dart';
import 'providers/cemetery_provider.dart';
import 'providers/grave_site_provider.dart';
import 'providers/mosque_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/cemetery_service.dart';
import 'services/grave_site_service.dart';
import 'services/mosque_service.dart';
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: authService,
            apiService: apiService,
          )..checkAuthStatus(),
        ),
        ChangeNotifierProvider(
          create: (_) => MosqueProvider(MosqueService(apiService)),
        ),
        ChangeNotifierProvider(
          create: (_) => CemeteryProvider(CemeteryService(apiService)),
        ),
        ChangeNotifierProvider(
          create: (_) => GraveSiteProvider(GraveSiteService(apiService)),
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
        if (auth.isLoggedIn) return const DashboardScreen();
        return const LoginScreen();
      },
    );
  }
}
