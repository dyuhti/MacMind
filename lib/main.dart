import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'screens/splash_loader_screen.dart';
import 'screens/login_screen.dart';
import 'screens/new_case_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anesthetic Consumption Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: FutureBuilder<bool>(
        future: AuthService.shouldAutoLogin(),
        builder: (context, snapshot) {
          // While checking prefs, show splash loader
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashLoaderScreen();
          }

          // If auto-login is enabled and prefs are valid, go directly to NewCaseScreen
          if (snapshot.hasData && snapshot.data == true) {
            return const NewCaseScreen();
          }

          // Otherwise, show login screen
          return const LoginScreen();
        },
      ),
    );
  }
}
