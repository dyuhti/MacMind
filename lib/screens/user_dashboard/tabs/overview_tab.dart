import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../widgets/stat_card.dart';
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
      if (!mounted) return;
      if (r1['success'] == true) {
        setState(() {
          _data = r1['user'] as Map<String, dynamic>?;
        });
      } else {
        _error = r1['message']?.toString();
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: List.generate(6, (_) => const DashboardCardSkeleton()),
        ),
      );
    }
    if (_error != null) return ErrorBanner(message: _error!);
    if (_data == null) return const SizedBox.shrink();

    final u = _data!;

    final cards = [
      StatCard(
        label: 'Total Cases', value: (u['case_count'] ?? 0).toString(),
        icon: Icons.science_outlined, color: const Color(0xFF2563EB),
        background: const Color(0xFFEFF6FF),
        subtitle: 'Volatile anesthetic cases',
      ),
      StatCard(
        label: 'Total O\u2082 Calc', value: (u['oxygen_count'] ?? 0).toString(),
        icon: Icons.air_outlined, color: const Color(0xFF0D9488),
        background: const Color(0xFFF0FDFB),
        subtitle: 'Oxygen calculations',
      ),
      StatCard(
        label: 'Favorites', value: (u['favorite_count'] ?? 0).toString(),
        icon: Icons.star_outline, color: const Color(0xFFF59E0B),
        background: const Color(0xFFFFFBEB),
      ),
      StatCard(
        label: 'Feedback', value: (u['feedback_count'] ?? 0).toString(),
        icon: Icons.feedback_outlined, color: const Color(0xFFE11D48),
        background: const Color(0xFFFFF1F2),
      ),
      StatCard(
        label: 'Logins', value: (u['login_count'] ?? 0).toString(),
        icon: Icons.login_outlined, color: const Color(0xFF8B5CF6),
        background: const Color(0xFFF5F3FF),
      ),
      StatCard(
        label: 'Sessions', value: (u['total_sessions'] ?? 0).toString(),
        icon: Icons.timer_outlined, color: const Color(0xFFEC4899),
        background: const Color(0xFFFDF2F8),
      ),
      StatCard(
        label: 'Avg Daily', value: '${u['average_daily_usage_mins'] ?? 0}',
        icon: Icons.trending_up_outlined, color: const Color(0xFF3B82F6),
        background: const Color(0xFFEFF6FF),
        subtitle: 'Calculations per day',
      ),
      StatCard(
        label: 'Account Age', value: '${u['account_age_days'] ?? 0}d',
        icon: Icons.calendar_today_outlined, color: const Color(0xFF6366F1),
        background: const Color(0xFFEEF2FF),
      ),
    ];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            itemCount: cards.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (_, i) => cards[i],
          ),
          const SizedBox(height: 20),
          if (u['most_used_calculator'] != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Row(children: [
                Icon(Icons.star_outlined,
                    color: Theme.of(context).colorScheme.tertiary, size: 20),
                const SizedBox(width: 8),
                Text('Most Used: ',
                    style: TextStyle(
                        fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                Expanded(
                  child: Text(u['most_used_calculator'].toString(),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface)),
                ),
              ]),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
