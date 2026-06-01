import 'package:flutter/material.dart';

import '../services/home_stats_service.dart';
import '../services/user_session.dart';
import '../widgets/app_header.dart';
import '../widgets/macmind_design.dart';
import 'case_history_screen.dart';
import 'formulas_and_constants_module_screen.dart';
import 'oxygen_cylinder_module_screen.dart';
import 'settings_screen.dart';
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
  int _recordsTabRefreshToken = 0;
  late Future<HomeStatsData> _homeStatsFuture;

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

  static const List<_QuickStatCardData> _quickStatsCards = [
    _QuickStatCardData(
      title: 'Total Calculations',
      icon: Icons.calculate_rounded,
      iconBackground: MacMindColors.blue50,
      iconColor: MacMindColors.blue600,
    ),
    _QuickStatCardData(
      title: 'Saved Records',
      icon: Icons.folder_copy_outlined,
      iconBackground: MacMindColors.teal50,
      iconColor: MacMindColors.teal400,
    ),
    _QuickStatCardData(
      title: "Today's Calculations",
      icon: Icons.analytics_outlined,
      iconBackground: MacMindColors.amber50,
      iconColor: MacMindColors.amber400,
    ),
    _QuickStatCardData(
      title: 'Most Used Module',
      icon: Icons.trending_up_rounded,
      iconBackground: MacMindColors.gray50,
      iconColor: MacMindColors.gray600,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _homeStatsFuture = HomeStatsService.fetchHomeStats();
    HomeStatsService.refreshNotifier.addListener(_refreshHomeStats);
  }

  @override
  void dispose() {
    HomeStatsService.refreshNotifier.removeListener(_refreshHomeStats);
    super.dispose();
  }

  void _refreshHomeStats() {
    if (!mounted) {
      return;
    }

    setState(() {
      _homeStatsFuture = HomeStatsService.fetchHomeStats();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        _refreshHomeStats();
      }
      if (index == 1) {
        _recordsTabRefreshToken++;
      }
    });
  }

  List<Widget> get _screens => [
        _buildHomeTab(),
        CaseHistoryScreen(
          key: ValueKey(_recordsTabRefreshToken),
          onBack: () => _onItemTapped(0),
          onProfileTap: () => _onItemTapped(2),
        ),
        SettingsScreen(onBack: () => _onItemTapped(0)),
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
                const MacMindSectionLabel(text: 'Quick Stats'),
                const SizedBox(height: 8),
                FutureBuilder<HomeStatsData>(
                  future: _homeStatsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const _QuickStatsLoadingGrid();
                    }

                    final stats = snapshot.data ?? const HomeStatsData.unavailable();
                    return _QuickStatsGrid(stats: stats);
                  },
                ),
                const SizedBox(height: 22),
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

class _QuickStatCardData {
  final String title;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const _QuickStatCardData({
    required this.title,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });
}

class _QuickStatsGrid extends StatelessWidget {
  final HomeStatsData stats;

  const _QuickStatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cardValues = <String>[
      _formatCount(stats.totalCalculations),
      _formatCount(stats.savedRecords),
      _formatCount(stats.todaysCalculations),
      _formatMostUsedModule(stats),
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _HomeScreenState._quickStatsCards.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 112,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final card = _HomeScreenState._quickStatsCards[index];
        return _QuickStatCard(
          title: card.title,
          value: cardValues[index],
          icon: card.icon,
          iconBackground: card.iconBackground,
          iconColor: card.iconColor,
        );
      },
    );
  }

  String _formatCount(int? value) {
    if (value == null) {
      return '--';
    }
    return value.toString();
  }

  String _formatMostUsedModule(HomeStatsData stats) {
    if (stats.mostUsedModuleTitle == null || stats.mostUsedModuleTitle!.isEmpty) {
      return '--';
    }

    return stats.mostUsedModuleTitle!;
  }
}

class _QuickStatsLoadingGrid extends StatelessWidget {
  const _QuickStatsLoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisExtent: 112,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: MacMindColors.border),
            boxShadow: const [
              BoxShadow(
                color: MacMindColors.shadow,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: MacMindColors.gray50,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const Spacer(),
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: MacMindColors.gray50,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 18,
                width: 72,
                decoration: BoxDecoration(
                  color: MacMindColors.blue50,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const _QuickStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(18),
        splashColor: iconColor.withValues(alpha: 0.10),
        highlightColor: iconColor.withValues(alpha: 0.04),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: MacMindColors.border),
            boxShadow: const [
              BoxShadow(
                color: MacMindColors.shadow,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.22),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: iconBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: iconColor, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: MacMindColors.gray600,
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      value,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: MacMindColors.textDark,
                        letterSpacing: -0.1,
                        height: 1.08,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
            ],
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
