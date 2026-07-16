import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/loading_skeleton.dart';

class AuditLogTab extends StatefulWidget {
  final int userId;
  const AuditLogTab({super.key, required this.userId});

  @override
  State<AuditLogTab> createState() => _AuditLogTabState();
}

class _AuditLogTabState extends State<AuditLogTab> {
  List<dynamic> _logs = [];
  int _page = 1, _pages = 1, _total = 0;
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
      final result = await AdminService.getUserAuditLog(
        widget.userId, page: _page,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        final pag = result['pagination'] as Map<String, dynamic>? ?? {};
        setState(() {
          _logs = result['audit_logs'] as List<dynamic>? ?? [];
          _total = (pag['total'] as int?) ?? 0;
          _pages = (pag['pages'] as int?) ?? 1;
        });
      } else {
        _error = result['message']?.toString();
      }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const LoadingSkeleton()
              : _error != null
                  ? ErrorBanner(message: _error!)
                  : _logs.isEmpty
                      ? const EmptyState(
                          icon: Icons.history_outlined,
                          message: 'No audit log entries')
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            children: [
                              ..._logs.map((l) => _AuditLogItem(
                                  log: l as Map<String, dynamic>)),
                              if (_pages > 1) _pagination(),
                            ],
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _pagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _page > 1 ? () { _page--; _load(); } : null,
            icon: const Icon(Icons.chevron_left),
            color: _page > 1 ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
          ),
          Text('Page $_page of $_pages',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
          IconButton(
            onPressed: _page < _pages ? () { _page++; _load(); } : null,
            icon: const Icon(Icons.chevron_right),
            color: _page < _pages ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }
}

class _AuditLogItem extends StatelessWidget {
  final Map<String, dynamic> log;
  const _AuditLogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final action = log['action']?.toString() ?? '';
    final adminName = log['admin_name']?.toString() ?? '—';
    final oldVal = log['old_value']?.toString();
    final newVal = log['new_value']?.toString();
    final ts = log['timestamp']?.toString() ?? '';
    final date = ts.split('T').first;
    final time = ts.contains('T')
        ? ts.split('T').last.substring(0, 8)
        : '';

    IconData icon;
    Color color;
    switch (action) {
      case 'role_changed':
        icon = Icons.admin_panel_settings_outlined;
        color = const Color(0xFF8B5CF6);
        break;
      case 'password_reset_by_admin':
        icon = Icons.lock_reset_outlined;
        color = const Color(0xFFF59E0B);
        break;
      case 'account_unlocked':
        icon = Icons.lock_open_outlined;
        color = const Color(0xFF16A34A);
        break;
      case 'user_deactivated':
      case 'user_activated':
        icon = Icons.block_outlined;
        color = const Color(0xFFE11D48);
        break;
      case 'case_deleted':
        icon = Icons.delete_outline;
        color = const Color(0xFFE11D48);
        break;
      case 'sessions_terminated':
        icon = Icons.logout_outlined;
        color = const Color(0xFFEC4899);
        break;
      case 'notification_sent':
        icon = Icons.notifications_outlined;
        color = const Color(0xFF3B82F6);
        break;
      default:
        icon = Icons.circle_outlined;
        color = const Color(0xFF64748B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 2),
                Text('By: $adminName',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
                if (oldVal != null && oldVal.isNotEmpty)
                  Text('Old: $oldVal',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF94A3B8))),
                if (newVal != null && newVal.isNotEmpty)
                  Text('New: $newVal',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF94A3B8))),
                const SizedBox(height: 2),
                Text('$date $time',
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFFCBD5E1))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
