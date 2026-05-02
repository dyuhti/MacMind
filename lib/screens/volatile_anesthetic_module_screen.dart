import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import 'profile_screen.dart';
import '../widgets/macmind_design.dart';
import 'new_case_screen.dart';
import 'economy_calculator_screen.dart';

/// Screen B: Volatile Anesthetic Module
/// User selects between Calculation or Economy Calculator
class VolatileAnestheticModuleScreen extends StatelessWidget {
  const VolatileAnestheticModuleScreen({super.key});

  void _navigateToCalculation(BuildContext context) {
    // Navigate to NewCaseScreen (Screen A entry point)
    // This will then lead to ConsumptionCalculatorScreen (Screen C)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NewCaseScreen(),
      ),
    );
  }

  void _navigateToEconomyCalculator(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EconomyCalculatorScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              title: 'Volatile Anesthetic',
              breadcrumb: 'Home • Volatile Anesthetic',
              showBack: true,
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
                    icon: Icons.info_outline,
                    child: Text(
                      'Select a tool to calculate volatile anesthetic consumption or analyze costs',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        height: 1.5,
                        color: MacMindColors.gray600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const MacMindSectionLabel(text: 'Choose a tool'),
                  const SizedBox(height: 12),
                  MacMindOptionCard(
                    icon: Icons.calculate_outlined,
                    iconBackground: MacMindColors.blue50,
                    iconColor: MacMindColors.blue600,
                    title: 'Calculation',
                    subtitle: 'Calculate volatile anesthetic consumption',
                    badge: 'CAL',
                    badgeColor: MacMindColors.blue600,
                    badgeBackground: MacMindColors.blue50,
                    onTap: () => _navigateToCalculation(context),
                  ),
                  const SizedBox(height: 12),
                  MacMindOptionCard(
                    icon: Icons.trending_down_outlined,
                    iconBackground: MacMindColors.teal50,
                    iconColor: MacMindColors.teal600,
                    title: 'Economy Calculator',
                    subtitle: 'Interactive cost analysis and comparison',
                    badge: 'COST',
                    badgeColor: MacMindColors.teal600,
                    badgeBackground: MacMindColors.teal50,
                    onTap: () => _navigateToEconomyCalculator(context),
                  ),
                  const SizedBox(height: 24),
                  const MacMindHintCard(text: 'Select an option above to begin'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
