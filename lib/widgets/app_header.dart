import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_spacing.dart';

/// Reusable app header with icon, title, and subtitle
class AppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;

  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.calculate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Icon in rounded square
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          ),
          child: Icon(
            icon,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Title
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        // Subtitle
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMedium,
              ),
        ),
      ],
    );
  }
}
