import 'package:flutter/material.dart';
import '../config/app_spacing.dart';
import '../widgets/app_header.dart';
import 'profile_screen.dart';
import '../widgets/case_history_dialog.dart';
import '../widgets/macmind_design.dart';
import 'new_case_screen.dart';
import 'login_screen.dart';

/// Dashboard/Calculator screen
class DashboardScreen extends StatefulWidget {
  final bool isGuest;

  const DashboardScreen({
    super.key,
    this.isGuest = false,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          SafeArea(
            top: false,
            left: false,
            right: false,
            child: AppHeader(
              title: 'Anesthetic Consumption Calculator',
              breadcrumb: 'Home • Calculator',
              showBack: true,
              onBack: () => Navigator.pop(context),
              onProfileTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppHeaderActionButton(
                    icon: Icons.history,
                    tooltip: 'View History',
                    onTap: () => showCaseHistoryDialog(context),
                  ),
                  const SizedBox(width: 8),
                  AppHeaderActionButton(
                    icon: Icons.logout,
                    tooltip: 'Logout',
                    onTap: _handleLogout,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF5F7FA),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: MacMindColors.blue50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.calculate_outlined,
                            size: 30,
                            color: MacMindColors.blue600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Volatile Anesthetic Calculation',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: MacMindColors.textDark,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Clinical calculator for anesthetic consumption and dose planning',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            height: 1.45,
                            color: MacMindColors.gray600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _navigateToNewCase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MacMindColors.blue600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'New Case',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToNewCase() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NewCaseScreen(caseData: null),
      ),
    );
  }

  void _handleLogout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }
}


