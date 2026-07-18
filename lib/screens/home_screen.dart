import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/timer_data.dart';
import '../providers/timer_provider.dart';
import '../services/home_stats_service.dart';
import '../services/native_timer_bridge.dart';

import '../services/user_session.dart';
import '../widgets/app_header.dart';
import '../widgets/macmind_design.dart';
import 'case_history_screen.dart';
import 'formulas_and_constants_module_screen.dart';
import 'oxygen_consumption_table_screen.dart';
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

  void _openRunningTimer(BuildContext context, TimerData timer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OxygenConsumptionTableScreen(
          cylinderType: timer.cylinderType,
          pressurePsi: timer.pressurePsi,
          totalContent: timer.totalOxygenContent,
          timerId: timer.timerId,
        ),
      ),
    );
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
                Consumer<TimerProvider>(
                  builder: (context, timerProvider, _) {
                    final activeTimers = timerProvider.activeTimers;
                    if (activeTimers.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const MacMindSectionLabel(text: 'Running Timers'),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                '${activeTimers.length} active',
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: MacMindColors.gray400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...activeTimers.map((timer) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RunningTimerCard(
                            timer: timer,
                            onTap: () => _openRunningTimer(context, timer),
                            onDelete: () {
                              timerProvider.removeTimer(timer.timerId);
                              NativeTimerBridge.deleteTimer(timer.timerId);
                            },
                            onPause: () {
                              final remaining = timer.remainingSeconds;
                              final updated = timer.copyWith(
                                status: TimerStatus.paused,
                                endTime: null,
                                pausedRemainingSeconds: remaining,
                              );
                              timerProvider.updateTimer(updated);
                              NativeTimerBridge.pauseTimer(
                                timerId: timer.timerId,
                                remainingSeconds: remaining,
                              );
                            },
                            onResume: () {
                              final remaining = timer.remainingSeconds;
                              final newEnd = DateTime.now().add(
                                Duration(seconds: remaining),
                              );
                              final updated = timer.copyWith(
                                status: TimerStatus.running,
                                endTime: newEnd,
                                pausedRemainingSeconds: null,
                              );
                              timerProvider.updateTimer(updated);
                              NativeTimerBridge.resumeTimer(
                                timerId: timer.timerId,
                                newFinishTimestamp:
                                    newEnd.millisecondsSinceEpoch,
                              );
                            },
                          ),
                        )),
                      ],
                    );
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

class _RunningTimerCard extends StatelessWidget {
  final TimerData timer;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onPause;
  final VoidCallback? onResume;

  const _RunningTimerCard({
    required this.timer,
    required this.onTap,
    this.onDelete,
    this.onPause,
    this.onResume,
  });

  String _formatCountdown(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatStartedTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final amPm = hour < 12 ? 'AM' : 'PM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $amPm';
  }

  String _dynamicStatusLabel() {
    if (timer.isPaused) return 'Paused';
    final pct = timer.durationSeconds > 0
        ? ((timer.remainingSeconds / timer.durationSeconds) * 100).round()
        : 0;
    if (pct > 50) return 'Running';
    if (pct > 25) return 'Halfway';
    if (pct > 10) return 'Running Low';
    if (pct > 0) return 'Almost Empty';
    return 'Expired';
  }

  Color _statusColor(String label) {
    switch (label) {
      case 'Paused': return const Color(0xFFF59E0B);
      case 'Halfway': return const Color(0xFF3B82F6);
      case 'Running Low': return const Color(0xFFF97316);
      case 'Almost Empty': return const Color(0xFFDC2626);
      case 'Expired': return const Color(0xFF991B1B);
      default: return const Color(0xFF16A34A);
    }
  }

  Color _statusBg(String label) {
    switch (label) {
      case 'Paused': return const Color(0xFFFFF7ED);
      case 'Halfway': return const Color(0xFFEFF6FF);
      case 'Running Low': return const Color(0xFFFFF7ED);
      case 'Almost Empty': return const Color(0xFFFEE2E2);
      case 'Expired': return const Color(0xFFFEE2E2);
      default: return const Color(0xFFEAF8EF);
    }
  }

  Color _statusBorder(String label) {
    switch (label) {
      case 'Paused': return const Color(0xFFFED7AA);
      case 'Halfway': return const Color(0xFFBFDBFE);
      case 'Running Low': return const Color(0xFFFED7AA);
      case 'Almost Empty': return const Color(0xFFFCA5A5);
      case 'Expired': return const Color(0xFFFCA5A5);
      default: return const Color(0xFFCDE8D7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = timer.isRunning;
    final isPaused = timer.isPaused;
    final statusLabel = _dynamicStatusLabel();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusBg(statusLabel),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: _statusBorder(statusLabel)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPaused ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                  size: 10,
                                  color: _statusColor(statusLabel),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _statusColor(statusLabel),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timer.cylinderType,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: MacMindColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatCountdown(timer.remainingSeconds),
                          style: const TextStyle(
                            fontFamily: 'Roboto Mono',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: MacMindColors.textDark,
                            fontFeatures: [FontFeature.tabularFigures()],
                            letterSpacing: 0.2,
                          ),
                        ),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_vert, size: 18, color: MacMindColors.gray400),
                          onSelected: (value) {
                            switch (value) {
                              case 'pause':
                                onPause?.call();
                                break;
                              case 'resume':
                                onResume?.call();
                                break;
                              case 'delete':
                                onDelete?.call();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            if (isRunning)
                              const PopupMenuItem(
                                value: 'pause',
                                child: Row(
                                  children: [
                                    Icon(Icons.pause, size: 18, color: MacMindColors.gray600),
                                    SizedBox(width: 8),
                                    Text('Pause'),
                                  ],
                                ),
                              ),
                            if (isPaused)
                              const PopupMenuItem(
                                value: 'resume',
                                child: Row(
                                  children: [
                                    Icon(Icons.play_arrow, size: 18, color: MacMindColors.gray600),
                                    SizedBox(width: 8),
                                    Text('Resume'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Color(0xFFDC2626))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Started ${_formatStartedTime(timer.startedAt)}',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: MacMindColors.gray400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
