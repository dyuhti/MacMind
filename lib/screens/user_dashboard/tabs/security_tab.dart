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
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? error;

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset Password',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: newPasswordCtrl,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () {
                            setDialogState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                        ),
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(error!,
                            style: const TextStyle(
                                color: Color(0xFFE11D48), fontSize: 12)),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final np = newPasswordCtrl.text.trim();
                    final cp = confirmPasswordCtrl.text.trim();
                    if (np.length < 6) {
                      setDialogState(() =>
                          error = 'Password must be at least 6 characters');
                      return;
                    }
                    if (np != cp) {
                      setDialogState(() =>
                          error = 'Passwords do not match');
                      return;
                    }
                    Navigator.of(ctx).pop({
                      'new_password': np,
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final apiResult = await AdminService.adminResetUserPassword(
      widget.userId,
      newPassword: result['new_password'],
    );
    if (apiResult['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
      _load();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(apiResult['message']?.toString() ?? 'Failed'),
          backgroundColor: const Color(0xFFE11D48),
        ),
      );
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'Never';
    try {
      final parts = iso.split('T');
      if (parts.length != 2) return iso;
      return '${parts[0]} ${parts[1].substring(0, 8)}';
    } catch (_) {
      return iso;
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
                            padding: const EdgeInsets.only(bottom: 16),
                            children: [
                              _infoCard('Password Last Changed',
                                  _formatDate(_security!['password_last_changed']?.toString())),
                              _infoCard('Last Login',
                                  _formatDate(_security!['last_login']?.toString())),
                              _infoCard('Current Device',
                                  _security!['current_device']?.toString() ?? 'Unknown'),
                              _infoCard('Current Platform',
                                  _security!['current_platform']?.toString() ?? 'Unknown'),
                              _infoCard('Failed Login Attempts',
                                  '${_security!['failed_logins'] ?? 0}'),
                              _infoCard('Current Sessions',
                                  '${_security!['current_sessions'] ?? 0}'),
                              _infoCard('Account Status',
                                  _statusLabelText(_security!['account_status']?.toString() ?? 'active')),
                              _infoCard('Blocked Status',
                                  _security!['is_blocked'] == true ? 'Yes' : 'No'),
                              const SizedBox(height: 16),
                              if ((_security!['current_sessions'] as int? ?? 0) > 0)
                                _actionButton('Terminate Sessions',
                                    Icons.logout_outlined, const Color(0xFFF59E0B), _terminateSessions),
                              _actionButton('Reset Password',
                                  Icons.lock_reset_outlined, const Color(0xFF8B5CF6), _resetPassword),
                            ],
                          ),
                        ),
        ),
      ],
    );
  }

  String _statusLabelText(String status) {
    switch (status) {
      case 'active': return 'Active';
      case 'inactive': return 'Inactive';
      case 'deactivated': return 'Deactivated';
      default: return status;
    }
  }

  Widget _infoCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          const SizedBox(width: 12),
          Text(value,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
