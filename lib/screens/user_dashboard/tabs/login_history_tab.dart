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
      final result = await AdminService.getUserLoginHistory(
        widget.userId, page: _page,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        final pag = result['pagination'] as Map<String, dynamic>? ?? {};
        setState(() {
          _history = result['login_history'] as List<dynamic>? ?? [];
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
                  : _history.isEmpty
                      ? const EmptyState(
                          icon: Icons.login_outlined,
                          message: 'No login history')
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            children: [
                              ..._history.map((h) => _HistoryItem(
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

class _HistoryItem extends StatelessWidget {
  final Map<String, dynamic> h;
  const _HistoryItem({required this.h});

  @override
  Widget build(BuildContext context) {
    final status = h['status']?.toString() ?? 'success';
    final loginTime = h['login_time']?.toString() ?? '';
    final logoutTime = h['logout_time']?.toString() ?? '';
    final duration = h['session_duration']?.toString() ?? '—';
    final platform = h['platform']?.toString() ?? '—';
    final device = h['device']?.toString() ?? '—';
    final browser = h['browser']?.toString() ?? '—';
    final loginDate = loginTime.split('T').first;
    final loginTimeOnly = loginTime.contains('T')
        ? loginTime.split('T').last.substring(0, 8)
        : '';

    final isSuccess = status == 'success';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: isSuccess
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFE11D48),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSuccess ? 'Successful Login' : 'Failed Login',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: isSuccess
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE11D48)),
                ),
                const SizedBox(height: 2),
                Text('$loginDate $loginTimeOnly',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8))),
                if (platform != '—' || device != '—')
                  Text('$platform · $device · $browser',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFFCBD5E1))),
                if (logoutTime.isNotEmpty)
                  Text('Logout: ${logoutTime.split('T').first}',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFFCBD5E1))),
                Text('Session: ${duration}s',
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
