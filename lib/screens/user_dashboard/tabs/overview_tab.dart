import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/chart_card.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/error_banner.dart';

class OverviewTab extends StatefulWidget {
  final int userId;
  const OverviewTab({super.key, required this.userId});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  Map<String, dynamic>? _data;
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
      final r1 = await AdminService.getUserDashboard(widget.userId);
      final r2 = await AdminService.getUserAnalytics(widget.userId);
      if (!mounted) return;
      if (r1['success'] == true && r2['success'] == true) {
        setState(() {
          _data = r1['user'] as Map<String, dynamic>?;
          _analytics = r2['analytics'] as Map<String, dynamic>?;
        });
      } else {
        _error = r1['message']?.toString() ?? r2['message']?.toString();
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Wrap(spacing: 12, runSpacing: 12,
          children: List.generate(6, (_) =>
              const SizedBox(width: 160, child: DashboardCardSkeleton())));
    }
    if (_error != null) return ErrorBanner(message: _error!);
    if (_data == null) return const SizedBox.shrink();

    final u = _data!;
    final a = _analytics ?? {};

    final cards = [
      ('Total Cases', (u['case_count'] ?? 0).toString(),
          Icons.science_outlined, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
      ('Total O₂ Calc', (u['oxygen_count'] ?? 0).toString(),
          Icons.air_outlined, const Color(0xFF0D9488), const Color(0xFFF0FDFB)),
      ('Favorites', (u['favorite_count'] ?? 0).toString(),
          Icons.star_outline, const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
      ('Feedback', (u['feedback_count'] ?? 0).toString(),
          Icons.feedback_outlined, const Color(0xFFE11D48), const Color(0xFFFFF1F2)),
      ('Logins', (u['login_count'] ?? 0).toString(),
          Icons.login_outlined, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
      ('Sessions', (u['total_sessions'] ?? 0).toString(),
          Icons.timer_outlined, const Color(0xFFEC4899), const Color(0xFFFDF2F8)),
      ('Avg Daily', '${u['average_daily_usage_mins'] ?? 0}',
          Icons.trending_up_outlined, const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
      ('Account Age', '${u['account_age_days'] ?? 0}d',
          Icons.calendar_today_outlined, const Color(0xFF6366F1), const Color(0xFFEEF2FF)),
    ];

    final weekly = (a['weekly_activity'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final monthly = (a['monthly_activity'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final calcUsage = (a['calculator_usage'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12,
              children: cards.map((c) => StatCard(
                  label: c.$1, value: c.$2, icon: c.$3,
                  color: c.$4, background: c.$5)).toList()),
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
          if (u['most_used_calculator'] != null)
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
                Text(u['most_used_calculator'].toString(),
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
