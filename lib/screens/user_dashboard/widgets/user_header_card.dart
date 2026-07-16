import 'package:flutter/material.dart';

class UserHeaderCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserHeaderCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isActive = user['is_active'] as bool? ?? true;
    final role = (user['role']?.toString() ?? 'user').toUpperCase();
    final name = user['full_name']?.toString() ?? '—';
    final email = user['email']?.toString() ?? '—';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final createdAt = _formatDate(user['created_at']?.toString());
    final lastLogin = user['last_login'] != null
        ? _formatDate(user['last_login']['time']?.toString())
        : 'Never';
    final platform = user['platform']?.toString() ?? '—';
    final device = user['device']?.toString() ?? '—';
    final accountAge = user['account_age_days']?.toString() ?? '—';
    final lastActivity = user['last_activity'] != null
        ? _formatDate(user['last_activity']?.toString())
        : 'No activity';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B))),
                    const SizedBox(height: 2),
                    Text(email,
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
                        _chip(
                            isActive ? 'ACTIVE' : 'INACTIVE',
                            isActive
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFE11D48),
                            isActive
                                ? const Color(0xFFF0FDF4)
                                : const Color(0xFFFFF1F2)),
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
          _infoRow(Icons.calendar_today_outlined, 'Registered', createdAt),
          _infoRow(Icons.login_outlined, 'Last Login', lastLogin),
          _infoRow(Icons.smartphone_outlined, 'Platform', platform),
          _infoRow(Icons.devices_outlined, 'Device', device),
          _infoRow(Icons.timer_outlined, 'Account Age', '$accountAge days'),
          _infoRow(Icons.circle_outlined, 'Last Active', lastActivity),
        ],
      ),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF64748B))),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B))),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
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
}
