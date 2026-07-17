import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tzlib;
import 'config/app_theme.dart';
import 'config/api_config.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/speech_smoke_test_screen.dart';
import 'screens/delete_account_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'services/notification_service.dart';
// speech_input_service removed - replaced by self-contained widgets
import 'providers/case_provider.dart';
import 'providers/timer_provider.dart';
import 'widgets/permission_lifecycle_manager.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics());
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  tz.initializeTimeZones();
  try {
    final dynamic localTimeZoneResult = await FlutterTimezone.getLocalTimezone();
    final String timeZoneName = localTimeZoneResult is String
      ? localTimeZoneResult
      : localTimeZoneResult.name.toString();
    tzlib.setLocalLocation(tzlib.getLocation(timeZoneName));
    debugPrint('🕒 Local timezone configured: $timeZoneName');
  } catch (error) {
    debugPrint('🕒 Failed to configure local timezone, falling back to UTC: $error');
    tzlib.setLocalLocation(tzlib.getLocation('UTC'));
  }
  await NotificationService().initialize();
  await NotificationService().requestPermissions();
  debugPrint('🔐 GROQ_API_KEY loaded: ${(dotenv.env['GROQ_API_KEY'] ?? '').isNotEmpty}');

  // Log startup configuration
  debugPrint('🚀 MacMind App Starting...');
  debugPrint('📡 API Base URL: ${ApiConfig.baseUrl}');
  debugPrint('🔍 Is Release Mode: $kReleaseMode');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _adminRoute(AdminSection section) {
    return FutureBuilder<bool>(
      future: AuthService.isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.data == true) {
          return AdminDashboardScreen(initialSection: section);
        }

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await AuthService.logout();
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You are not authorized.')),
            );
          }
        });

        return const Scaffold(body: SizedBox.expand());
      },
    );
  }

  Future<String?> _bootstrapApp() async {
    final shouldAutoLogin = await AuthService.shouldAutoLogin();
    if (!shouldAutoLogin) return null;

    final token = await AuthService.getToken();
    if (token == null) {
      await AuthService.logout();
      return null;
    }

    try {
      await ProfileService.hydrateUserSession();
      final role = await AuthService.getRole();
      debugPrint('✅ Auto-login successful - token validated, role: $role');
      return role;
    } catch (e) {
      debugPrint('❌ Failed to hydrate user session: $e');
      await AuthService.logout();
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CaseProvider()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
      ],
      child: MaterialApp(
        title: 'Anesthetic Consumption Calculator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/speech-smoke-test': (context) => const SpeechSmokeTestScreen(),
          '/delete-account': (context) => const DeleteAccountScreen(),
          '/login': (context) => const LoginScreen(),
          '/admin/dashboard': (context) => _adminRoute(AdminSection.dashboard),
          '/admin/users': (context) => _adminRoute(AdminSection.users),
          '/admin/calculators': (context) => _adminRoute(AdminSection.entries),
          '/admin/entries': (context) => _adminRoute(AdminSection.entries),
          '/admin/feedback': (context) => _adminRoute(AdminSection.feedback),
        },
        scrollBehavior: const AppScrollBehavior(),
        home: FutureBuilder<String?>(
          future: _bootstrapApp(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.white,
                body: SizedBox.expand(),
              );
            }

            final autoLoginRole = snapshot.data;
            if (autoLoginRole != null) {
              if (autoLoginRole == 'admin') {
                return const AdminDashboardScreen(initialSection: AdminSection.dashboard);
              }
              return PermissionLifecycleManager(
                child: const HomeScreen(),
              );
            }

            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
