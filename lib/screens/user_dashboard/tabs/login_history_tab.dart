import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/loading_skeleton.dart';

IconData _platformIcon(String? platform) {
  switch (platform?.toLowerCase()) {
    case 'android': return Icons.android_outlined;
    case 'ios': return Icons.phone_iphone_outlined;
    case 'windows': return Icons.laptop_windows_outlined;
    case 'macos': return Icons.laptop_mac_outlined;
    case 'linux': return Icons.terminal_outlined;
    case 'web': return Icons.language_outlined;
    default: return Icons.devices_outlined;
  }
}

Color _platformColor(String? platform) {
  switch (platform?.toLowerCase()) {
    case 'android': return const Color(0xFF16A34A);
    case 'ios': return const Color(0xFF1E293B);
    case 'windows': return const Color(0xFF2563EB);
    case 'macos': return const Color(0xFF7C3AED);
    case 'linux': return const Color(0xFFF59E0B);
    case 'web': return const Color(0xFF0D9488);
    default: return const Color(0xFF64748B);
  }
}

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.login_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('${_history.length} session${_history.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const Spacer(),
              Text('Page $_page of $_pages',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
                              ..._history.asMap().entries.map((entry) =>
                                _LoginCard(
                                  h: entry.value as Map<String, dynamic>,
                                  isActive: _isActive(entry.value as Map<String, dynamic>),
                                  isLatest: entry.key == 0,
                                )),
                              if (_pages > 1) _pagination(),
                            ],
                          ),
                        ),
        ),
      ],
    );
  }

  bool _isActive(Map<String, dynamic> h) {
    return h['status']?.toString() == 'success' && h['logout_time'] == null;
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
  final bool isActive;
  final bool isLatest;

  const _LoginCard({
    required this.h,
    required this.isActive,
    required this.isLatest,
  });

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '\u2014';
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
    final platform = h['platform']?.toString();
    final device = h['device']?.toString() ?? 'Unknown';
    final browser = h['browser']?.toString();
    final ip = h['ip_address']?.toString();

    final isSuccess = status == 'success';
    final date = loginTime.contains('T') ? loginTime.split('T').first : loginTime;
    final time = loginTime.contains('T') ? loginTime.split('T').last.substring(0, 8) : '';

    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? cs.primary.withValues(alpha: 0.4)
              : isLatest
                  ? cs.primary.withValues(alpha: 0.2)
                  : cs.outlineVariant,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: cs.primary.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]
            : [BoxShadow(color: cs.shadow.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _platformColor(platform).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_platformIcon(platform), size: 18, color: _platformColor(platform)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isActive ? 'Active Session' : (isLatest ? 'Latest Session' : (isSuccess ? 'Successful Login' : 'Failed Login')),
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: isActive ? cs.primary : cs.onSurface),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text('LIVE',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: cs.primary)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text('$date  $time',
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
                    ],
                  ),
                ),
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? cs.primary
                        : (isSuccess ? cs.onSurfaceVariant : cs.error),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: cs.outlineVariant),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _detailChip(Icons.timer_outlined, 'Duration', _formatDuration(sessionDuration), cs),
                _detailChip(Icons.smartphone_outlined, 'Platform', platform ?? '\u2014', cs),
                _detailChip(Icons.devices_outlined, 'Device', device, cs),
                if (browser != null && browser.isNotEmpty)
                  _detailChip(Icons.language_outlined, 'Browser', browser, cs),
                if (ip != null && ip.isNotEmpty)
                  _detailChip(Icons.wifi_outlined, 'IP', ip, cs),
                _detailChip(Icons.info_outlined, 'Status', isSuccess ? 'Success' : 'Failed', cs),
                if (logoutTime.isNotEmpty)
                  _detailChip(Icons.logout_outlined, 'Logged Out',
                      logoutTime.contains('T') ? logoutTime.split('T').last.substring(0, 8) : '', cs),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailChip(IconData icon, String label, String value, ColorScheme cs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text('$label ',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        Text(value,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface)),
      ],
    );
  }
}
