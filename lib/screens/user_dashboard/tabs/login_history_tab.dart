import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/loading_skeleton.dart';

class LoginHistoryTab extends StatefulWidget {
  final int userId;
  const LoginHistoryTab({super.key, required this.userId});

  @override
  State<LoginHistoryTab> createState() => _LoginHistoryTabState();
}

class _LoginHistoryTabState extends State<LoginHistoryTab> {
  List<dynamic> _history = [];
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
      final result = await AdminService.getUserLoginHistory(
        widget.userId, page: _page,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        final pag = result['pagination'] as Map<String, dynamic>? ?? {};
        setState(() {
          _history = result['login_history'] as List<dynamic>? ?? [];
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
                  : _history.isEmpty
                      ? const EmptyState(
                            icon: Icons.login_outlined,
                            message: 'No login history',
                            subtitle: 'User has not logged in yet',
                          )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: 16),
                            children: [
                              ..._history.map((h) => _LoginCard(
                                  h: h as Map<String, dynamic>)),
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

class _LoginCard extends StatelessWidget {
  final Map<String, dynamic> h;
  const _LoginCard({required this.h});

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '—';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final status = h['status']?.toString() ?? 'success';
    final loginTime = h['login_time']?.toString() ?? '';
    final logoutTime = h['logout_time']?.toString() ?? '';
    final sessionDuration = h['session_duration'] as int?;
    final platform = h['platform']?.toString() ?? 'Unknown';
    final device = h['device']?.toString() ?? 'Unknown';
    final browser = h['browser']?.toString();

    final isSuccess = status == 'success';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFE11D48),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isSuccess ? 'Successful Login' : 'Failed Login',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: isSuccess
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE11D48)),
                ),
                const Spacer(),
                Text(
                  loginTime.contains('T')
                      ? loginTime.split('T').last.substring(0, 8)
                      : '',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _detailRow(Icons.calendar_today_outlined, 'Date',
                loginTime.contains('T') ? loginTime.split('T').first : loginTime),
            _detailRow(Icons.access_time_outlined, 'Login Time',
                loginTime.contains('T') ? loginTime.split('T').last.substring(0, 8) : '—'),
            if (logoutTime.isNotEmpty)
              _detailRow(Icons.logout_outlined, 'Logout Time',
                  logoutTime.contains('T') ? '${logoutTime.split('T').first} ${logoutTime.split('T').last.substring(0, 8)}' : logoutTime),
            _detailRow(Icons.timer_outlined, 'Session Duration', _formatDuration(sessionDuration)),
            const Divider(height: 16),
            _detailRow(Icons.devices_outlined, 'Device', device),
            _detailRow(Icons.smartphone_outlined, 'Platform', platform),
            if (browser != null && browser.isNotEmpty)
              _detailRow(Icons.language_outlined, 'Browser', browser),
            _detailRow(Icons.info_outlined, 'Status',
                isSuccess ? 'Success' : 'Failed'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(value,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B))),
          ),
        ],
      ),
    );
  }
}
