import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/case_service.dart';
import '../widgets/app_header.dart';
import '../widgets/macmind_design.dart';
import '../services/home_stats_service.dart';
import 'settings_screen.dart';
import 'new_case_screen.dart';
import 'economy_calculator_screen.dart';
import '../providers/case_provider.dart';

/// Screen B: Volatile Anesthetic Module
/// User selects between Calculation or Economy Calculator
class VolatileAnestheticModuleScreen extends StatefulWidget {
  const VolatileAnestheticModuleScreen({super.key});

  @override
  State<VolatileAnestheticModuleScreen> createState() => _VolatileAnestheticModuleScreenState();
}

class _VolatileAnestheticModuleScreenState extends State<VolatileAnestheticModuleScreen> {
  late Future<_VolatileModuleData> _moduleDataFuture;

  @override
  void initState() {
    super.initState();
    _moduleDataFuture = _fetchModuleData();
    HomeStatsService.refreshNotifier.addListener(_refreshModuleData);
  }

  @override
  void dispose() {
    HomeStatsService.refreshNotifier.removeListener(_refreshModuleData);
    super.dispose();
  }

  Future<_VolatileModuleData> _fetchModuleData() async {
    final result = await CaseService.getAllCases();
    if (!mounted) {
      return const _VolatileModuleData.empty();
    }

    if (result['success'] != true) {
      return const _VolatileModuleData.empty();
    }

    final cases = (result['cases'] as List<dynamic>?) ?? [];
    final parsedCases = <_VolatileCaseRecord>[];

    for (final raw in cases) {
      if (raw is Map<String, dynamic>) {
        final createdAt = _parseBackendTimestamp('${raw['created_at'] ?? raw['createdAt'] ?? ''}');
        final agent = _extractAnestheticAgent(raw);
        if (createdAt != null) {
          parsedCases.add(
            _VolatileCaseRecord(
              createdAt: createdAt,
              agent: agent.isEmpty ? 'Unknown' : agent,
            ),
          );
        }
      }
    }

    parsedCases.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final totalCalculations = parsedCases.length;
    final lastUsedAt = parsedCases.isNotEmpty ? parsedCases.first.createdAt : null;

    final agentCounts = <String, int>{};
    final canonicalLabel = <String, String>{};
    for (final record in parsedCases) {
      final normalizedAgent = record.agent.toLowerCase();
      canonicalLabel.putIfAbsent(normalizedAgent, () => record.agent);
      agentCounts[normalizedAgent] = (agentCounts[normalizedAgent] ?? 0) + 1;
    }

    String? mostUsedAgent;
    if (agentCounts.isNotEmpty) {
      final winner = agentCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      mostUsedAgent = canonicalLabel[winner];
    }

    final recentCalculations = parsedCases.take(3).toList();

    return _VolatileModuleData(
      totalCalculations: totalCalculations,
      lastUsedAt: lastUsedAt,
      mostUsedAgent: mostUsedAgent,
      recentCalculations: recentCalculations,
    );
  }

  Future<void> _refreshModuleData() async {
    if (!mounted) return;
    setState(() {
      _moduleDataFuture = _fetchModuleData();
    });
  }

  Future<void> _navigateToCalculation(BuildContext context) async {
    context.read<CaseProvider>().startCreateMode();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NewCaseScreen(caseData: null),
      ),
    );
    await _refreshModuleData();
  }

  void _navigateToEconomyCalculator(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EconomyCalculatorScreen(),
      ),
    );
  }

  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now().toUtc();
    final event = timestamp.toUtc();
    final difference = now.difference(event);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    }
    if (difference.inHours < 24) {
      return difference.inHours == 1 ? '1 hour ago' : '${difference.inHours} hours ago';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    return '${difference.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: false,
      body: Column(
        children: [
          SafeArea(
            top: false,
            left: false,
            right: false,
            child: AppHeader(
              title: 'Volatile Anesthetic',
              breadcrumb: 'Home • Volatile Anesthetic',
              showBack: true,
              onProfileTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
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
                  const MacMindInfoCard(
                    icon: Icons.info_outline,
                    child: Text(
                      'Select a tool to calculate volatile anesthetic consumption or analyze costs',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        height: 1.5,
                        color: MacMindColors.gray600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const MacMindSectionLabel(text: 'Quick Stats'),
                  const SizedBox(height: 8),
                  FutureBuilder<_VolatileModuleData>(
                    future: _moduleDataFuture,
                    builder: (context, snapshot) {
                      final data = snapshot.data;
                      final isLoading = snapshot.connectionState != ConnectionState.done;
                      return _VolatileInsightGrid(
                        data: data,
                        isLoading: isLoading,
                        formatRelativeTime: _formatRelativeTime,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const MacMindSectionLabel(text: 'Choose a tool'),
                  const SizedBox(height: 12),
                  MacMindOptionCard(
                    icon: Icons.calculate_outlined,
                    iconBackground: MacMindColors.blue50,
                    iconColor: MacMindColors.blue600,
                    title: 'Calculation',
                    subtitle: 'Calculate volatile anesthetic consumption',
                    badge: 'CAL',
                    badgeColor: MacMindColors.blue600,
                    badgeBackground: MacMindColors.blue50,
                    onTap: () => _navigateToCalculation(context),
                  ),
                  const SizedBox(height: 12),
                  MacMindOptionCard(
                    icon: Icons.trending_down_outlined,
                    iconBackground: MacMindColors.teal50,
                    iconColor: MacMindColors.teal600,
                    title: 'Economy Calculator',
                    subtitle: 'Interactive cost analysis and comparison',
                    badge: 'COST',
                    badgeColor: MacMindColors.teal600,
                    badgeBackground: MacMindColors.teal50,
                    onTap: () => _navigateToEconomyCalculator(context),
                  ),
                  const SizedBox(height: 24),
                  const MacMindHintCard(text: 'Select an option above to begin'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VolatileCaseRecord {
  final DateTime createdAt;
  final String agent;

  const _VolatileCaseRecord({required this.createdAt, required this.agent});
}

DateTime? _parseBackendTimestamp(String timestamp) {
  if (timestamp.isEmpty) return null;

  final parsed = DateTime.tryParse(timestamp);
  if (parsed == null) return null;

  final hasTimeZone = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(timestamp);
  if (hasTimeZone) {
    return parsed;
  }

  // Backend timestamps are stored as UTC without a timezone marker.
  // Treat naive values as UTC so the relative time is accurate in local time.
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  ).toLocal();
}

String _extractAnestheticAgent(Map<String, dynamic> raw) {
  final agentValue = raw['anesthetic_agent'] ?? raw['anestheticAgent'] ?? raw['selected_agent'] ?? raw['selectedAgent'] ?? '';
  return '$agentValue'.trim();
}

class _VolatileModuleData {
  final int totalCalculations;
  final DateTime? lastUsedAt;
  final String? mostUsedAgent;
  final List<_VolatileCaseRecord> recentCalculations;

  const _VolatileModuleData({
    required this.totalCalculations,
    required this.lastUsedAt,
    required this.mostUsedAgent,
    required this.recentCalculations,
  });

  const _VolatileModuleData.empty()
      : totalCalculations = 0,
        lastUsedAt = null,
        mostUsedAgent = null,
        recentCalculations = const [];
}

class _VolatileInsightGrid extends StatelessWidget {
  final _VolatileModuleData? data;
  final bool isLoading;
  final String Function(DateTime timestamp) formatRelativeTime;

  const _VolatileInsightGrid({
    required this.data,
    required this.isLoading,
    required this.formatRelativeTime,
  });

  @override
  Widget build(BuildContext context) {
    final moduleData = data;
    final lastUsedAt = moduleData?.lastUsedAt;
    final lastUsedValue = lastUsedAt != null ? formatRelativeTime(lastUsedAt) : '--';
    final recentCountValue = moduleData != null ? moduleData.recentCalculations.length.toString() : '0';

    final cards = [
      _InsightCardConfig(
        title: 'Total Calculations',
        value: data?.totalCalculations.toString() ?? '--',
        icon: Icons.calculate_outlined,
        iconBackground: MacMindColors.blue50,
        iconColor: MacMindColors.blue600,
      ),
      _InsightCardConfig(
        title: 'Last Used',
        value: lastUsedValue,
        icon: Icons.schedule_outlined,
        iconBackground: MacMindColors.amber50,
        iconColor: MacMindColors.amber600,
      ),
      _InsightCardConfig(
        title: 'Most Used Agent',
        value: data?.mostUsedAgent ?? '--',
        icon: Icons.trending_up_outlined,
        iconBackground: MacMindColors.teal50,
        iconColor: MacMindColors.teal600,
      ),
      _InsightCardConfig(
        title: 'Recent Calculations',
        value: recentCountValue,
        icon: Icons.history_outlined,
        iconBackground: MacMindColors.gray50,
        iconColor: MacMindColors.gray600,
      ),
    ];

    if (isLoading) {
      return const _VolatileInsightLoadingGrid();
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 112,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        return _InsightCard(config: cards[index]);
      },
    );
  }
}

class _VolatileInsightLoadingGrid extends StatelessWidget {
  const _VolatileInsightLoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 112,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: MacMindColors.surface,
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: MacMindColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const Spacer(),
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: MacMindColors.gray50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 20,
                  width: 80,
                  decoration: BoxDecoration(
                    color: MacMindColors.blue50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InsightCardConfig {
  final String title;
  final String? value;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const _InsightCardConfig({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });
}

class _InsightCard extends StatelessWidget {
  final _InsightCardConfig config;

  const _InsightCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(18),
        splashColor: config.iconColor.withAlpha(25),
        highlightColor: config.iconColor.withAlpha(10),
        child: Container(
          decoration: BoxDecoration(
            color: MacMindColors.surface,
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
                    color: config.iconColor.withAlpha(56),
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
                            color: config.iconBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(config.icon, color: config.iconColor, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            config.title,
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
                      config.value ?? '--',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: MacMindColors.textDark,
                        letterSpacing: -0.1,
                        height: 1.08,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
