import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'config/app_theme.dart';
import 'screens/splash_loader_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'services/user_session.dart';

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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _bootstrapApp() async {
    final shouldAutoLogin = await AuthService.shouldAutoLogin();
    if (!shouldAutoLogin) {
      return false;
    }

    await ProfileService.hydrateUserSession();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anesthetic Consumption Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scrollBehavior: const AppScrollBehavior(),
      home: FutureBuilder<bool>(
        future: _bootstrapApp(),
        builder: (context, snapshot) {
          // While checking prefs, show splash loader
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashLoaderScreen();
          }

          // If auto-login is enabled and prefs are valid, go directly to HomeScreen
          // This enforces the new multi-step navigation flow
          if (snapshot.hasData && snapshot.data == true) {
            return const HomeScreen();
          }

          // Otherwise, show login screen
          return const LoginScreen();
        },
      ),
    );
  }
}
