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
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'services/notification_service.dart';
// speech_input_service removed - replaced by self-contained widgets
import 'providers/case_provider.dart';
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

  Future<bool> _bootstrapApp() async {
    // Check if user should auto-login (has remember me flag)
    final shouldAutoLogin = await AuthService.shouldAutoLogin();
    if (!shouldAutoLogin) {
      return false;
    }

    // Verify token is still valid
    final token = await AuthService.getToken();
    if (token == null) {
      // No token found, logout
      await AuthService.logout();
      return false;
    }

    // Attempt to hydrate user session from stored data
    try {
      await ProfileService.hydrateUserSession();
      debugPrint('✅ Auto-login successful - token validated');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to hydrate user session: $e');
      await AuthService.logout();
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CaseProvider()),
      ],
      child: MaterialApp(
        title: 'Anesthetic Consumption Calculator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/speech-smoke-test': (context) => const SpeechSmokeTestScreen(),
        },
        scrollBehavior: const AppScrollBehavior(),
        home: FutureBuilder<bool>(
          future: _bootstrapApp(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.white,
                body: SizedBox.expand(),
              );
            }

            if (snapshot.hasData && snapshot.data == true) {
              return PermissionLifecycleManager(
                child: const HomeScreen(),
              );
            }

            // Otherwise, show login screen
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
