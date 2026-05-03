import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'config/api_config.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'services/user_session.dart';
import 'providers/case_provider.dart';

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
  // Log startup configuration
  print('🚀 MacMind App Starting...');
  print('📡 API Base URL: ${ApiConfig.baseUrl}');
  print('🔍 Is Release Mode: $kReleaseMode');
  
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CaseProvider()),
      ],
      child: MaterialApp(
        title: 'Anesthetic Consumption Calculator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
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
              return const HomeScreen();
            }

            // Otherwise, show login screen
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
