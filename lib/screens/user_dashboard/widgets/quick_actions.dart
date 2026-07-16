import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final role = user['role']?.toString() ?? 'user';
    final isActive = user['is_active'] as bool? ?? true;

    final actions = [
      _ActionDef('Edit User', Icons.edit_outlined,
          const Color(0xFF2563EB), () => _editUser(context)),
      _ActionDef(
        isActive ? 'Deactivate' : 'Activate',
        isActive ? Icons.block_outlined : Icons.check_circle_outline,
        isActive ? const Color(0xFFF59E0B) : const Color(0xFF16A34A),
        () => _toggleActive(context),
      ),
      _ActionDef('Delete User', Icons.delete_outline,
          const Color(0xFFE11D48), () => _deleteUser(context),
          destructive: true),
      _ActionDef('Reset Password', Icons.lock_reset_outlined,
          const Color(0xFF8B5CF6), () => _resetPassword(context)),
      _ActionDef(
        role == 'admin' ? 'Remove Admin' : 'Promote to Admin',
        role == 'admin' ? Icons.arrow_downward : Icons.arrow_upward,
        const Color(0xFF0D9488),
        () => _toggleRole(context),
      ),
      _ActionDef('Unlock Account', Icons.lock_open_outlined,
          const Color(0xFF3B82F6), () => _unlockAccount(context)),
      _ActionDef('Send Notification', Icons.notifications_outlined,
          const Color(0xFFEC4899), () => _sendNotification(context)),
      _ActionDef('Export Data', Icons.download_outlined,
          const Color(0xFF6366F1), () => _exportData(context)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actions.map((a) => _ActionButton(def: a)).toList(),
        ),
      ],
    );
  }

  void _editUser(BuildContext context) {
    final nameCtrl = TextEditingController(text: user['full_name']?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit User',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit feature: name update requires backend PATCH')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
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

  Future<void> _deleteUser(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      'Delete User',
      'Permanently delete this user? This cannot be undone.',
      destructive: true,
      confirmText: 'Delete',
    );
    if (!confirmed) return;
    final result = await AdminService.deleteUser(userId);
    _showResult(context, result);
    if (result['success'] == true) onRefresh();
  }

  Future<void> _resetPassword(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      'Reset Password',
      'This will generate a new password. The new password will be shown once.',
      destructive: false,
    );
    if (!confirmed) return;
    final result = await AdminService.adminResetUserPassword(userId);
    if (result['success'] == true && result['new_password'] != null) {
      await Clipboard.setData(ClipboardData(text: result['new_password']));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New password: ${result['new_password']} (copied)'),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } else {
      _showResult(context, result);
    }
    if (result['success'] == true) onRefresh();
  }

  Future<void> _toggleRole(BuildContext context) async {
    final role = user['role']?.toString() ?? 'user';
    final isAdmin = role == 'admin';
    final action = isAdmin ? 'remove admin from' : 'promote';
    final confirmed = await showConfirmDialog(
      context,
      isAdmin ? 'Remove Admin' : 'Promote to Admin',
      'Are you sure you want to $action this user?',
    );
    if (!confirmed) return;
    final newRole = isAdmin ? 'user' : 'admin';
    final result = await AdminService.updateUserRole(userId, newRole);
    _showResult(context, result);
    if (result['success'] == true) onRefresh();
  }

  Future<void> _unlockAccount(BuildContext context) async {
    final result = await AdminService.unlockUserAccount(userId);
    _showResult(context, result);
    if (result['success'] == true) onRefresh();
  }

  Future<void> _sendNotification(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Send Notification',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, {
              'title': titleCtrl.text,
              'message': msgCtrl.text,
            }),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final apiResult = await AdminService.sendUserNotification(userId, result);
    _showResult(context, apiResult);
  }

  Future<void> _exportData(BuildContext context) async {
    final result = await AdminService.exportUserData(userId);
    if (result['success'] == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export data loaded (console)')),
      );
      debugPrint('Export: ${result['export']}');
    } else {
      _showResult(context, result);
    }
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

class _ActionDef {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool destructive;

  _ActionDef(this.label, this.icon, this.color, this.onTap, {this.destructive = false});
}

class _ActionButton extends StatelessWidget {
  final _ActionDef def;
  const _ActionButton({required this.def});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: MaterialButton(
        onPressed: def.onTap,
        height: 56,
        elevation: 0,
        color: def.color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: def.color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(def.icon, size: 18, color: def.color),
            const SizedBox(width: 6),
            Text(
              def.label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: def.color),
            ),
          ],
        ),
      ),
    );
  }
}
