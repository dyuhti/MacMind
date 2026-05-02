import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import 'profile_screen.dart';
import '../widgets/macmind_design.dart';
import 'clinical_tips_module_screen.dart';
import 'new_case_screen.dart';
import 'oxygen_cylinder_module_screen.dart';
import 'volatile_anesthetic_module_screen.dart';
import '../services/user_session.dart';

/// Screen A: Home / Module Selection
/// Entry point after login with 3 main modules
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final List<ModuleCard> modules = [
    ModuleCard(
      id: 'volatile',
      title: 'Volatile Anesthetic\nConsumption',
      subtitle: 'Calculate consumption & economy',
      icon: Icons.science_outlined,
      color: MacMindColors.blue600,
      iconBackground: MacMindColors.blue50,
    ),
    ModuleCard(
      id: 'oxygen',
      title: 'Oxygen Cylinder\nDuration',
      subtitle: 'Calculate cylinder duration',
      icon: Icons.air_outlined,
      color: MacMindColors.teal400,
      iconBackground: MacMindColors.teal50,
    ),
    ModuleCard(
      id: 'clinical_tips',
      title: 'Clinical Tips',
      subtitle: 'AI-powered anesthesia insights',
      icon: Icons.lightbulb_outline,
      color: MacMindColors.amber400,
      iconBackground: MacMindColors.amber50,
    ),
  ];

  /// Get time-based greeting
  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  /// Build dynamic greeting with user name
  String _buildGreeting() {
    final greeting = _getTimeBasedGreeting();
    final userName = (UserSession.name != null && UserSession.name!.isNotEmpty)
        ? UserSession.name!
        : "User";
    return "$greeting, $userName";
  }

  void _handleModuleSelection(BuildContext context, String moduleId) {
    switch (moduleId) {
      case 'volatile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const VolatileAnestheticModuleScreen(),
          ),
        );
        break;
      case 'oxygen':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const OxygenCylinderModuleScreen(),
          ),
        );
        break;
      case 'clinical_tips':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ClinicalTipsModuleScreen(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          SafeArea(
            top: false,
            left: false,
            right: false,
            child: AppHeader(
              subtitle: _buildGreeting(),
              title: 'Select a Module to get started',
              onProfileTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF5F7FA),
              padding: const EdgeInsets.all(16),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const MacMindSectionLabel(text: 'Clinical Modules'),
                  const SizedBox(height: 12),
                  for (final module in modules) ...[
                    MacMindModuleCard(
                      icon: module.icon,
                      iconBackground: module.iconBackground,
                      iconColor: module.color,
                      title: module.title,
                      subtitle: module.subtitle,
                      onTap: () => _handleModuleSelection(context, module.id),
                    ),
                    const SizedBox(height: 12),
                  ],
                  MacMindLegacyButton(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NewCaseScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          child: MacMindBottomNav(
            selectedIndex: 0,
            onTap: (index) {
              // Safe navigation: open Profile screen when Profile tab tapped (index 3)
              if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Model for Module Card Data
class ModuleCard {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color iconBackground;

  ModuleCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.iconBackground,
  });
}
