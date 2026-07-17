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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF4A90E2),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 14, height: 14,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        if (isOnline) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 4),
                                const Text('Online',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _chip(role, role == 'ADMIN'),
                        _statusChip(status),
                        if (currentSessions > 0)
                          _chip('$currentSessions session${currentSessions == 1 ? '' : 's'}', false),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
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
                        const SizedBox(height: 10),
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
        const SizedBox(height: 8),
        _infoRow(Icons.login_outlined, 'Last Login', lastLogin),
        const SizedBox(height: 8),
        _infoRow(_platformIcon(platform), 'Platform', platform),
      ],
    );
  }

  Widget _buildRightColumn(String device, String accountAge, String lastActivity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(Icons.devices_outlined, 'Device', device),
        const SizedBox(height: 8),
        _infoRow(Icons.timer_outlined, 'Account Age', '$accountAge days'),
        const SizedBox(height: 8),
        _infoRow(Icons.circle_outlined, 'Last Active', lastActivity),
      ],
    );
  }

  Widget _chip(String label, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFEFF6FF) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isAdmin ? const Color(0xFF4A90E2) : const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'active':
        color = const Color(0xFF10B981);
        label = 'Active';
        break;
      case 'inactive':
        color = const Color(0xFFF59E0B);
        label = 'Inactive';
        break;
      case 'deactivated':
        color = const Color(0xFFEF4444);
        label = 'Deactivated';
        break;
      default:
        color = const Color(0xFF6B7280);
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
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFF9CA3AF),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
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
