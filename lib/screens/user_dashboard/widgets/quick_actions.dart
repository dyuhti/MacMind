import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import 'confirm_dialog.dart';

class QuickActions extends StatelessWidget {
  final int userId;
  final Map<String, dynamic> user;
  final VoidCallback onRefresh;

  const QuickActions({
    super.key,
    required this.userId,
    required this.user,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = user['is_active'] as bool? ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final spacing = 8.0;
            final buttonWidth = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: buttonWidth,
                  child: _ActionButton(
                    icon: isActive
                        ? Icons.block_outlined
                        : Icons.check_circle_outline,
                    label: isActive ? 'Deactivate' : 'Activate',
                    color: isActive
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF16A34A),
                    onTap: () => _toggleActive(context),
                  ),
                ),
                SizedBox(
                  width: buttonWidth,
                  child: _ActionButton(
                    icon: Icons.lock_reset_outlined,
                    label: 'Reset Password',
                    color: const Color(0xFF8B5CF6),
                    onTap: () => _resetPassword(context),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _toggleActive(BuildContext context) async {
    final isActive = user['is_active'] as bool? ?? true;
    final action = isActive ? 'deactivate' : 'activate';
    final confirmed = await showConfirmDialog(
      context,
      '${action[0].toUpperCase()}${action.substring(1)} User',
      'Are you sure you want to $action this user?',
      destructive: !isActive,
    );
    if (!confirmed) return;
    final result = await AdminService.updateUserActive(userId, isActive: !isActive);
    _showResult(context, result);
    if (result['success'] == true) onRefresh();
  }

  Future<void> _resetPassword(BuildContext context) async {
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
                    Navigator.of(ctx).pop({'new_password': np});
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
      userId,
      newPassword: result['new_password'],
    );
    _showResult(context, apiResult);
    if (apiResult['success'] == true) onRefresh();
  }

  void _showResult(BuildContext context, Map<String, dynamic> result) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ??
            (result['success'] == true ? 'Done' : 'Failed')),
        backgroundColor: result['success'] == true
            ? const Color(0xFF16A34A)
            : const Color(0xFFE11D48),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
