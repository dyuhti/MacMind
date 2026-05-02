import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import 'profile_screen.dart';
import '../widgets/macmind_design.dart';

/// Screen B: Clinical Tips Module
/// Display AI-powered anesthesia insights and clinical tips
class ClinicalTipsModuleScreen extends StatelessWidget {
  const ClinicalTipsModuleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<ClinicalTip> tips = [
      ClinicalTip(
        title: 'Volatile Anesthetic Selection',
        subtitle: 'Choosing the Right Agent',
        content:
            'Consider patient factors, surgical duration, and specific agent properties. Isoflurane offers stable hemodynamics, while sevoflurane provides rapid emergence.',
        icon: Icons.science,
        color: const Color(0xFF4A90E2),
      ),
      ClinicalTip(
        title: 'Fresh Gas Flow Optimization',
        subtitle: 'Minimizing Waste',
        content:
            'Higher FGF rates increase consumption. Use low-flow techniques (0.5-2 L/min) when appropriate to reduce volatile anesthetic waste and cost.',
        icon: Icons.air,
        color: const Color(0xFF10B981),
      ),
      ClinicalTip(
        title: 'Oxygen Cylinder Management',
        subtitle: 'Safety First',
        content:
            'Always verify cylinder pressure before procedures. Monitor remaining duration and prepare backup. Never allow pressure to drop below 300 PSI.',
        icon: Icons.oil_barrel,
        color: const Color(0xFFF59E0B),
      ),
      ClinicalTip(
        title: 'Equipment Maintenance',
        subtitle: 'Vaporizer Care',
        content:
            'Regularly calibrate vaporizers and verify functioning. Incorrect calibration can lead to inadequate anesthesia or overdose.',
        icon: Icons.build,
        color: const Color(0xFFEF4444),
      ),
      ClinicalTip(
        title: 'Emergency Preparedness',
        subtitle: 'Always Be Ready',
        content:
            'Have backup oxygen and manual ventilation equipment available. Know your emergency cart location and protocols.',
        icon: Icons.emergency,
        color: const Color(0xFF8B5CF6),
      ),
      ClinicalTip(
        title: 'Patient Monitoring',
        subtitle: 'Anesthetic Depth Assessment',
        content:
            'Use clinical signs and monitoring devices (BIS, MAC) to assess anesthetic depth. Adjust agent concentration accordingly.',
        icon: Icons.monitor_heart,
        color: const Color(0xFF06B6D4),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: false,
      body: Column(
        children: [
          SafeArea(
            top: false,
            left: false,
            right: false,
            child: AppHeader(
              title: 'Clinical Tips',
              breadcrumb: 'Home • Clinical Tips',
              showBack: true,
              onBack: () => Navigator.pop(context),
              onProfileTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF5F7FA),
              padding: const EdgeInsets.all(16),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const MacMindInfoCard(
                    icon: Icons.auto_awesome,
                    child: Text(
                      'Expert-curated anesthesia insights to support safer decisions and better efficiency',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        height: 1.5,
                        color: MacMindColors.gray600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const MacMindSectionLabel(text: 'AI-powered insights'),
                  const SizedBox(height: 12),
                  ...tips.asMap().entries.map((entry) {
                    final index = entry.key;
                    final tip = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MacMindTipCard(
                        index: index + 1,
                        title: tip.title,
                        subtitle: tip.subtitle,
                        content: tip.content,
                        icon: tip.icon,
                        iconColor: tip.color,
                        iconBackground: tip.color.withValues(alpha: 0.15),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  const MacMindHintCard(text: 'Always follow your facility\'s protocols'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Model for Clinical Tip Data
class ClinicalTip {
  final String title;
  final String subtitle;
  final String content;
  final IconData icon;
  final Color color;

  ClinicalTip({
    required this.title,
    required this.subtitle,
    required this.content,
    required this.icon,
    required this.color,
  });
}
