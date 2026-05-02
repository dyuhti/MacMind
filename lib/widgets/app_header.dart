import 'package:flutter/material.dart';

class AppHeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final VoidCallback? onPressed;

  const AppHeaderActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class AppHeaderProfileAvatar extends StatelessWidget {
  final String profileLabel;

  const AppHeaderProfileAvatar({
    super.key,
    this.profileLabel = 'Dr',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      alignment: Alignment.center,
      child: Text(
        profileLabel,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? breadcrumb;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;
  final String profileLabel;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumb,
    this.showBack = false,
    this.onBack,
    this.trailing,
    this.profileLabel = 'Dr',
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        margin: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minHeight: 160,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D3B66), Color(0xFF1E5F9A)],
          ),
            boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (showBack)
                    _buildBackButton(context)
                  else
                    const SizedBox(width: 34, height: 34),
                  const Spacer(),
                  trailing ?? _buildProfileAvatar(),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                    height: 1.35,
                  ),
                ),
              ],
              if (breadcrumb != null && breadcrumb!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  breadcrumb!,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: onBack ?? () => Navigator.of(context).maybePop(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return AppHeaderProfileAvatar(profileLabel: profileLabel);
  }
}
