import 'package:flutter/material.dart';

import '../services/user_session.dart';
import '../widgets/app_header.dart';
import '../widgets/macmind_design.dart';
import 'case_history_screen.dart';
import 'formulas_and_constants_module_screen.dart';
import 'new_case_screen.dart';
import 'oxygen_cylinder_module_screen.dart';
import 'profile_screen.dart';
import 'volatile_anesthetic_module_screen.dart';

/// Screen A: Home / Module Selection
/// Entry point after login with 3 main modules
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

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
      id: 'formulas_and_constants',
      title: 'Formulas and Constants',
      subtitle: 'Anesthesia reference formulas',
      icon: Icons.lightbulb_outline,
      color: MacMindColors.amber400,
      iconBackground: MacMindColors.amber50,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> get _screens => [
        _buildHomeTab(),
        CaseHistoryScreen(
          onBack: () => _onItemTapped(0),
          onProfileTap: () => _onItemTapped(2),
        ),
        ProfileScreen(onBack: () => _onItemTapped(0)),
      ];

  /// Get time-based greeting
  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  /// Build dynamic greeting with user name
  String _buildGreeting() {
    final greeting = _getTimeBasedGreeting();
    final userName = (UserSession.name != null && UserSession.name!.isNotEmpty)
        ? UserSession.name!
        : 'User';
    return '$greeting, $userName';
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
      case 'formulas_and_constants':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const FormulasAndConstantsModuleScreen(),
          ),
        );
        break;
    }
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        SafeArea(
          top: false,
          left: false,
          right: false,
          child: AppHeader(
            subtitle: _buildGreeting(),
            title: 'Select a Module to get started',
            onProfileTap: () => _onItemTapped(2),
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
                        builder: (_) => const NewCaseScreen(caseData: null),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          child: MacMindBottomNav(
            selectedIndex: _selectedIndex,
            onTap: _onItemTapped,
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
