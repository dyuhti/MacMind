import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import 'login_screen.dart';

/// Splash/Welcome screen shown on app startup
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Top spacing
            const SizedBox(height: AppSpacing.xxl),

            // Header Section
            Column(
              children: [
                // Icon in rounded square
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
                  ),
                  child: const Icon(
                    Icons.calculate_outlined,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Title
                const Text(
                  'Anesthetic Consumption',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Subtitle - Calculator
                const Text(
                  'Calculator',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Description
                const Text(
                  'Professional tool for calculating anesthetic agent consumption',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Inter',
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Features Section
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
                  ),
                  child: Column(
                    children: [
                      // Feature 1: Multiple Agents
                      _FeatureItem(
                        icon: Icons.biotech_outlined,
                        title: 'Multiple Agents',
                        description:
                            'Support for Isoflurane, Sevoflurane, Desflurane, and Halothane',
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Feature 2: Three Formulas
                      _FeatureItem(
                        icon: Icons.calculate,
                        title: 'Three Formulas',
                        description:
                            "Biro's, Dion's, and Weight-Based calculation methods",
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Feature 3: Save & Export
                      _FeatureItem(
                        icon: Icons.save_outlined,
                        title: 'Save & Export',
                        description: 'Store cases and view complete history',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Action Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  // Start New Case Button
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.buttonHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                        ),
                      ),
                      child: const Text(
                        'Start New Case',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Medical Professionals Only
                  const Text(
                    'Medical professionals only',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Inter',
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Version Info
                  const Text(
                    'Version 1.0.0 • For clinical use only',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Inter',
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual feature item in splash screen
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: AppSpacing.iconMedium,
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Inter',
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
