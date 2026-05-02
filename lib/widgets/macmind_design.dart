import 'package:flutter/material.dart';

class MacMindColors {
  static const Color background = Color(0xFFF4F6FB);
  static const Color surface = Colors.white;
  static const Color blue50 = Color(0xFFE6F1FB);
  static const Color blue100 = Color(0xFFB5D4F4);
  static const Color blue200 = Color(0xFF85B7EB);
  static const Color blue400 = Color(0xFF378ADD);
  static const Color blue600 = Color(0xFF185FA5);
  static const Color blue800 = Color(0xFF0C447C);
  static const Color blue900 = Color(0xFF042C53);
  static const Color teal50 = Color(0xFFE1F5EE);
  static const Color teal400 = Color(0xFF1D9E75);
  static const Color teal600 = Color(0xFF0F6E56);
  static const Color amber50 = Color(0xFFFAEEDA);
  static const Color amber400 = Color(0xFFBA7517);
  static const Color amber600 = Color(0xFF854F0B);
  static const Color gray50 = Color(0xFFF1EFE8);
  static const Color gray100 = Color(0xFFD3D1C7);
  static const Color gray200 = Color(0xFFB4B2A9);
  static const Color gray400 = Color(0xFF888780);
  static const Color gray600 = Color(0xFF5F5E5A);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color border = Color(0xFFE5E7EB);
  static const Color shadow = Color(0x0D000000);
}

class MacMindStatusBar extends StatelessWidget {
  const MacMindStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: MacMindColors.blue900,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            '9:41',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xE6FFFFFF),
              letterSpacing: 0.3,
            ),
          ),
          Row(
            children: List.generate(
              3,
              (_) => Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(left: 5),
                decoration: const BoxDecoration(
                  color: Color(0xCCFFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MacMindHeroHeader extends StatelessWidget {
  final String brand;
  final String subtitle;
  final String greeting;
  final String title;
  final String avatarLabel;

  const MacMindHeroHeader({
    super.key,
    required this.brand,
    required this.subtitle,
    required this.greeting,
    required this.title,
    this.avatarLabel = 'Dr',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MacMindColors.blue900,
      padding: const EdgeInsets.fromLTRB(20, 20, 24, 32),
      child: Stack(
        children: [
          Positioned(
            top: -42,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1F378ADD),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            left: 36,
            child: Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x0AFFFFFF),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0x26FFFFFF),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.medical_services_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            brand,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Color(0x8CFFFFFF),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0x26FFFFFF),
                      border: Border.all(color: const Color(0x4DFFFFFF)),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      avatarLabel,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                greeting,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0x8CFFFFFF),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'DM Serif Display',
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MacMindSectionLabel extends StatelessWidget {
  final String text;

  const MacMindSectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.6,
        color: MacMindColors.gray400,
      ),
    );
  }
}

class MacMindModuleCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const MacMindModuleCard({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: MacMindColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: MacMindColors.border),
            boxShadow: const [
              BoxShadow(
                color: MacMindColors.shadow,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: MacMindColors.textDark,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: MacMindColors.gray400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: MacMindColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: MacMindColors.shadow,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: MacMindColors.gray400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MacMindLegacyButton extends StatelessWidget {
  final VoidCallback onTap;

  const MacMindLegacyButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: MacMindColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MacMindColors.gray100, width: 1.5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_outlined, size: 18, color: MacMindColors.gray400),
              SizedBox(width: 8),
              Text(
                'New Case (Legacy)',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: MacMindColors.gray400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MacMindBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const MacMindBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem('Home', Icons.home_outlined, Icons.home),
      _NavItem('Modules', Icons.grid_view_outlined, Icons.grid_view),
      _NavItem('Records', Icons.description_outlined, Icons.description),
      _NavItem('Profile', Icons.person_outline, Icons.person),
    ];

    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      decoration: const BoxDecoration(
        color: MacMindColors.surface,
        border: Border(top: BorderSide(color: Color(0x0F000000))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: selected ? MacMindColors.blue600 : const Color(0x661A1A2E),
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: selected ? MacMindColors.blue800 : MacMindColors.blue800.withValues(alpha: 0.42),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavItem(this.label, this.icon, this.selectedIcon);
}

class MacMindTopNav extends StatelessWidget {
  final String title;
  final List<String> breadcrumb;
  final VoidCallback onBack;
  final Widget? trailing;

  const MacMindTopNav({
    super.key,
    required this.title,
    required this.breadcrumb,
    required this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MacMindColors.blue900, MacMindColors.blue800],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1E378ADD),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onBack,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0x1FFFFFFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x26FFFFFF)),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      trailing!,
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (int index = 0; index < breadcrumb.length; index++) ...[
                      Text(
                        breadcrumb[index],
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: index == breadcrumb.length - 1 ? FontWeight.w500 : FontWeight.w400,
                          color: index == breadcrumb.length - 1
                              ? const Color(0xD9FFFFFF)
                              : const Color(0x73FFFFFF),
                        ),
                      ),
                      if (index != breadcrumb.length - 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 1),
                          decoration: const BoxDecoration(
                            color: Color(0x66FFFFFF),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MacMindInfoCard extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const MacMindInfoCard({super.key, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: MacMindColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MacMindColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: MacMindColors.blue50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: MacMindColors.blue600),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class MacMindOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final Color badgeBackground;
  final VoidCallback onTap;

  const MacMindOptionCard({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.badgeBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: MacMindColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: MacMindColors.border),
            boxShadow: const [
              BoxShadow(
                color: MacMindColors.shadow,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: MacMindColors.textDark,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: MacMindColors.gray400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.chevron_right, size: 18, color: MacMindColors.gray400),
            ],
          ),
        ),
      ),
    );
  }
}

class MacMindHintCard extends StatelessWidget {
  final String text;

  const MacMindHintCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: MacMindColors.blue50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1A185FA5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: MacMindColors.blue600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: MacMindColors.blue800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MacMindTipCard extends StatelessWidget {
  final int index;
  final String title;
  final String subtitle;
  final String content;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const MacMindTipCard({
    super.key,
    required this.index,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MacMindColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MacMindColors.border),
        boxShadow: const [
          BoxShadow(
            color: MacMindColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: MacMindColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: MacMindColors.gray400,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}