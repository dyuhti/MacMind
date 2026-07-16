import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/chart_card.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/error_banner.dart';

class UserAnalyticsTab extends StatefulWidget {
  final int userId;
  const UserAnalyticsTab({super.key, required this.userId});

  @override
  State<UserAnalyticsTab> createState() => _UserAnalyticsTabState();
}

class _UserAnalyticsTabState extends State<UserAnalyticsTab> {
  Map<String, dynamic>? _analytics;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await AdminService.getUserAnalytics(widget.userId);
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _analytics = result['analytics'] as Map<String, dynamic>?;
        });
      } else {
        _error = result['message']?.toString();
      }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Wrap(spacing: 12, runSpacing: 12,
          children: List.generate(4, (_) =>
              const SizedBox(width: 160, child: DashboardCardSkeleton())));
    }
    if (_error != null) return ErrorBanner(message: _error!);
    if (_analytics == null) return const SizedBox.shrink();

    final a = _analytics!;
    final weekly = (a['weekly_activity'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ?? [];
    final monthly = (a['monthly_activity'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ?? [];
    final calcUsage = (a['calculator_usage'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ?? [];
    final featureUsage = (a['feature_usage_breakdown'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ?? [];

    final cards = [
      ('Total Cases', (a['total_cases'] ?? 0).toString(),
          Icons.science_outlined, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
      ('Total O₂', (a['total_oxygen'] ?? 0).toString(),
          Icons.air_outlined, const Color(0xFF0D9488), const Color(0xFFF0FDFB)),
      ('30d Cases', (a['cases_last_30_days'] ?? 0).toString(),
          Icons.trending_up_outlined, const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
      ('30d O₂', (a['oxygen_last_30_days'] ?? 0).toString(),
          Icons.air_outlined, const Color(0xFFE11D48), const Color(0xFFFFF1F2)),
      ('Avg/Week', '${a['avg_calculations_per_week'] ?? 0}',
          Icons.calendar_view_week_outlined, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
      ('Days Since Activity', '${a['days_since_last_activity'] ?? 0}',
          Icons.timer_off_outlined, const Color(0xFFEC4899), const Color(0xFFFDF2F8)),
    ];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12,
              children: cards.map((c) => StatCard(
                  label: c.$1, value: c.$2,
                  icon: c.$3, color: c.$4, background: c.$5)).toList()),
          const SizedBox(height: 24),
          if (weekly.isNotEmpty) ...[
            BarChartCard(
                data: weekly, title: 'Weekly Activity',
                barLabel: 'Entries', barColor: const Color(0xFF2563EB)),
            const SizedBox(height: 16),
          ],
          if (monthly.isNotEmpty) ...[
            BarChartCard(
                data: monthly, title: 'Monthly Activity',
                barLabel: 'Entries', barColor: const Color(0xFF0D9488)),
            const SizedBox(height: 16),
          ],
          if (calcUsage.isNotEmpty) ...[
            PieChartCard(data: calcUsage, title: 'Calculator Usage'),
            const SizedBox(height: 16),
          ],
          if (featureUsage.isNotEmpty) ...[
            PieChartCard(
                data: featureUsage, title: 'Feature Usage Breakdown'),
            const SizedBox(height: 16),
          ],
          if (a['most_used_calculator'] != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(children: [
                const Icon(Icons.star_outlined,
                    color: Color(0xFFF59E0B), size: 20),
                const SizedBox(width: 8),
                const Text('Most Used: ',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF64748B))),
                Text(a['most_used_calculator'].toString(),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B))),
              ]),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
