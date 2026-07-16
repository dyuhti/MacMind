import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/confirm_dialog.dart';

class SecurityTab extends StatefulWidget {
  final int userId;
  const SecurityTab({super.key, required this.userId});

  @override
  State<SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends State<SecurityTab> {
  Map<String, dynamic>? _security;
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
      final result = await AdminService.getUserSecurity(widget.userId);
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _security = result['security'] as Map<String, dynamic>?;
        });
      } else {
        _error = result['message']?.toString();
      }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _terminateSessions() async {
    final confirmed = await showConfirmDialog(
      context, 'Terminate Sessions',
      'Terminate all active sessions for this user?',
    );
    if (!confirmed) return;
    final result = await AdminService.terminateUserSessions(widget.userId);
    if (result['success'] == true) _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Done')),
      );
    }
  }

  Future<void> _resetPassword() async {
    final confirmed = await showConfirmDialog(
      context, 'Reset Password',
      'Reset this user password?',
    );
    if (!confirmed) return;
    final result = await AdminService.adminResetUserPassword(widget.userId);
    if (result['success'] == true && result['new_password'] != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New password: ${result['new_password']} (copied to clipboard)'),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  Future<void> _unlock() async {
    final result = await AdminService.unlockUserAccount(widget.userId);
    if (result['success'] == true) _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Done')),
      );
    }
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
                  : _security == null
                      ? const EmptyState(
                          icon: Icons.security_outlined,
                          message: 'No security data')
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            children: [
                              _infoCard('Password Last Changed',
                                  _security!['password_last_changed']?.toString() ?? '—'),
                              _infoCard('Failed Logins',
                                  '${_security!['failed_logins'] ?? 0}'),
                              _infoCard('Current Sessions',
                                  '${_security!['current_sessions'] ?? 0}'),
                              _infoCard('Blocked',
                                  _security!['is_blocked'] == true ? 'Yes' : 'No'),
                              _infoCard('2FA Enabled',
                                  _security!['two_factor_enabled'] == true ? 'Yes' : 'No'),
                              const SizedBox(height: 16),
                              if (_security!['known_devices'] is List)
                                ...(_security!['known_devices'] as List).map(
                                  (d) => _infoCard('Device', d['device'] ?? '—'),
                                ),
                              const SizedBox(height: 16),
                              _actionButton('Terminate Sessions',
                                  Icons.logout_outlined, Colors.orange, _terminateSessions),
                              _actionButton('Reset Password',
                                  Icons.lock_reset_outlined, Colors.purple, _resetPassword),
                              _actionButton('Unlock Account',
                                  Icons.lock_open_outlined, Colors.green, _unlock),
                            ],
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _infoCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF64748B))),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: MaterialButton(
        onPressed: onTap,
        height: 52,
        elevation: 0,
        color: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
