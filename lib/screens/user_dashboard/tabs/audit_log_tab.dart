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
  int _page = 1, _pages = 1;
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
                              ..._logs.map((l) => _AuditCard(
                                  log: l as Map<String, dynamic>)),
                              if (_pages > 1) _pagination(),
                              const SizedBox(height: 16),
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

class _AuditCard extends StatelessWidget {
  final Map<String, dynamic> log;
  const _AuditCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final action = log['action']?.toString() ?? '';
    final adminName = log['admin_name']?.toString() ?? '\u2014';
    final oldVal = log['old_value']?.toString();
    final newVal = log['new_value']?.toString();
    final ts = log['timestamp']?.toString() ?? '';
    final date = ts.split('T').first;
    final time = ts.contains('T')
        ? ts.split('T').last.substring(0, 8)
        : '';

    Color chipColor;
    String displayAction;
    switch (action) {
      case 'role_changed':
        chipColor = const Color(0xFF8B5CF6);
        displayAction = 'Role Changed';
        break;
      case 'password_reset_by_admin':
        chipColor = const Color(0xFFF59E0B);
        displayAction = 'Password Reset';
        break;
      case 'account_unlocked':
        chipColor = const Color(0xFF16A34A);
        displayAction = 'Account Unlocked';
        break;
      case 'user_deactivated':
        chipColor = const Color(0xFFE11D48);
        displayAction = 'User Deactivated';
        break;
      case 'user_activated':
        chipColor = const Color(0xFF16A34A);
        displayAction = 'User Activated';
        break;
      case 'case_deleted':
        chipColor = const Color(0xFFE11D48);
        displayAction = 'Case Deleted';
        break;
      case 'sessions_terminated':
        chipColor = const Color(0xFFEC4899);
        displayAction = 'Sessions Terminated';
        break;
      case 'notification_sent':
        chipColor = const Color(0xFF3B82F6);
        displayAction = 'Notification Sent';
        break;
      default:
        chipColor = const Color(0xFF64748B);
        displayAction = action.replaceAll('_', ' ');
    }

    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    displayAction.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: chipColor),
                  ),
                ),
                const Spacer(),
                Text('$date $time',
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
              ],
            ),
            const SizedBox(height: 6),
            Text('By: $adminName',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant)),
            if (oldVal != null && oldVal.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Old: $oldVal',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
              ),
            if (newVal != null && newVal.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('New: $newVal',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
              ),
          ],
        ),
      ),
    );
  }
}
