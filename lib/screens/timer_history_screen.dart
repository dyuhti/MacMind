import 'package:flutter/material.dart';

import '../models/oxygen_timer_models.dart';
import '../services/admin_service.dart';
import '../services/oxygen_timer_service.dart';
import '../widgets/app_header.dart';
import 'settings_screen.dart';

class TimerHistoryScreen extends StatefulWidget {
  final int? userId;

  const TimerHistoryScreen({super.key, this.userId});

  @override
  State<TimerHistoryScreen> createState() => _TimerHistoryScreenState();
}

class _TimerHistoryScreenState extends State<TimerHistoryScreen> {
  late Future<List<OxygenTimerHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<OxygenTimerHistoryItem>> _loadHistory() async {
    if (widget.userId != null) {
      final result = await AdminService.getUserTimerHistory(widget.userId!);
      if (result['success'] == true) {
        final rawHistory = result['history'] as List<dynamic>? ?? [];
        return rawHistory
            .map((e) => OxygenTimerHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }
    return OxygenTimerApiService.fetchHistory();
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _historyFuture = _loadHistory();
    });
    await _historyFuture;
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '-';
    }

    final local = dateTime.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final amPm = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $hour:$minute $amPm';
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) {
      return '-';
    }

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    final parts = <String>[];
    if (hours > 0) {
      parts.add('${hours}h');
    }
    if (minutes > 0) {
      parts.add('${minutes}m');
    }
    if (remainingSeconds > 0 || parts.isEmpty) {
      parts.add('${remainingSeconds}s');
    }

    return parts.join(' ');
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'running':
        return const Color(0xFF16A34A);
      case 'paused':
        return const Color(0xFFF59E0B);
      case 'resumed':
        return const Color(0xFF0EA5E9);
      case 'stopped':
        return const Color(0xFFDC2626);
      case 'completed':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _statusBackground(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'running':
        return const Color(0xFFEAF8EF);
      case 'paused':
        return const Color(0xFFFFF7ED);
      case 'resumed':
        return const Color(0xFFE0F2FE);
      case 'stopped':
        return const Color(0xFFFEE2E2);
      case 'completed':
        return const Color(0xFFE8EEFF);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Widget _buildStatusChip(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _statusBackground(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        (status ?? '-').toUpperCase(),
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _statusColor(status),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(OxygenTimerHistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.cylinderType ?? '-',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              _buildStatusChip(item.timerStatus),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMetric('Date', _formatDateTime(item.createdAt)),
              _buildMetric('Pressure PSI', item.pressurePsi?.toStringAsFixed(1) ?? '-'),
              _buildMetric('Oxygen Content', '${item.totalOxygenContent?.toStringAsFixed(1) ?? '-'} L'),
              _buildMetric('Flow Rate', '${item.selectedFlowRate?.toStringAsFixed(1) ?? '-'} L/min'),
              _buildMetric('Duration', item.durationText ?? _formatDuration(item.durationSeconds)),
              _buildMetric('Started', _formatDateTime(item.startedAt)),
              _buildMetric('Completed', _formatDateTime(item.completedAt)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FB),
      body: Column(
        children: [
          SafeArea(
            top: false,
            left: false,
            right: false,
            child: AppHeader(
              title: 'Timer History',
              subtitle: 'Newest entries appear first',
              breadcrumb: 'Oxygen timer tracking',
              showBack: true,
              onBack: () => Navigator.pop(context),
              onProfileTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshHistory,
              child: FutureBuilder<List<OxygenTimerHistoryItem>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF0A4D8C)));
                  }

                  final history = snapshot.data ?? <OxygenTimerHistoryItem>[];

                  if (history.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Text(
                            'No timer history is available yet.',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: history.map(_buildRow).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}