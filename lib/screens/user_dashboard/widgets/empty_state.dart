import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(icon, size: 48, color: const Color(0xFF475569).withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: Color(0xFF475569))),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF94A3B8))),
            ],
          ],
        ),
      ),
    );
  }
}
