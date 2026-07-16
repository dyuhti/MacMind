import 'package:flutter/material.dart';

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

class UserHeaderCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserHeaderCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isActive = user['is_active'] as bool? ?? true;
    final role = (user['role']?.toString() ?? 'user').toUpperCase();
    final status = user['status']?.toString() ?? 'active';
    final name = user['full_name']?.toString() ?? '\u2014';
    final email = user['email']?.toString() ?? '\u2014';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final createdAt = _formatDate(user['created_at']?.toString());
    final lastLogin = user['last_login'] != null
        ? _formatDateTime(user['last_login']['time']?.toString())
        : 'Never';
    final platform = user['platform']?.toString() ?? 'Unknown';
    final device = user['device']?.toString() ?? 'Unknown';
    final accountAge = user['account_age_days']?.toString() ?? '0';
    final lastActivity = user['last_activity'] != null
        ? _formatDateTime(user['last_activity']?.toString())
        : 'No activity';
    final currentSessions = user['current_sessions'] as int? ?? 0;
    final isOnline = currentSessions > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline
              ? const Color(0xFF16A34A).withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
          width: isOnline ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: isActive
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF8FAFC),
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B))),
                        ),
                        if (isOnline) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 6, color: Color(0xFF16A34A)),
                                SizedBox(width: 4),
                                Text('Online',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _chip(role,
                            role == 'ADMIN'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF16A34A),
                            role == 'ADMIN'
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFF0FDF4)),
                        _statusChip(status),
                        if (currentSessions > 0)
                          _chip('$currentSessions session${currentSessions == 1 ? '' : 's'}',
                              const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 400;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildLeftColumn(createdAt, lastLogin, platform)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildRightColumn(device, accountAge, lastActivity)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildLeftColumn(createdAt, lastLogin, platform),
                        const SizedBox(height: 8),
                        _buildRightColumn(device, accountAge, lastActivity),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn(String createdAt, String lastLogin, String platform) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(Icons.calendar_today_outlined, 'Registered', createdAt),
        const SizedBox(height: 6),
        _infoRow(Icons.login_outlined, 'Last Login', lastLogin),
        const SizedBox(height: 6),
        _infoRow(_platformIcon(platform), 'Platform', platform),
      ],
    );
  }

  Widget _buildRightColumn(String device, String accountAge, String lastActivity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(Icons.devices_outlined, 'Device', device),
        const SizedBox(height: 6),
        _infoRow(Icons.timer_outlined, 'Account Age', '$accountAge days'),
        const SizedBox(height: 6),
        _infoRow(Icons.circle_outlined, 'Last Active', lastActivity),
      ],
    );
  }

  Widget _chip(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'active':
        color = const Color(0xFF16A34A);
        label = 'Active';
        break;
      case 'inactive':
        color = const Color(0xFFF59E0B);
        label = 'Inactive';
        break;
      case 'deactivated':
        color = const Color(0xFFE11D48);
        label = 'Deactivated';
        break;
      default:
        color = const Color(0xFF94A3B8);
        label = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF64748B))),
        Expanded(
          child: Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B))),
        ),
      ],
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '\u2014';
    try {
      final parts = iso.split('T');
      if (parts.isNotEmpty) {
        final dateParts = parts[0].split('-');
        if (dateParts.length == 3) {
          return '${dateParts[2]}/${dateParts[1]}/${dateParts[0]}';
        }
      }
      return iso.substring(0, 10);
    } catch (_) {
      return iso;
    }
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '\u2014';
    try {
      final parts = iso.split('T');
      if (parts.length == 2) {
        final dateParts = parts[0].split('-');
        if (dateParts.length == 3) {
          return '${dateParts[2]}/${dateParts[1]}/${dateParts[0]} ${parts[1].substring(0, 8)}';
        }
      }
      return iso.substring(0, 16);
    } catch (_) {
      return iso;
    }
  }
}
