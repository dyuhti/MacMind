import 'package:flutter/material.dart';
import '../models/onboarding_page.dart';
import '../widgets/onboarding_page_widget.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _current = 0;

  late final List<OnboardingPage> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      OnboardingPage(
        title: 'Welcome',
        subtitle: 'AI-Powered Clinical Assistant',
        icon: Icons.health_and_safety_outlined,
      ),
      OnboardingPage(
        title: 'Volatile Anaesthetic Calculator',
        subtitle: 'Accurate agent consumption calculations at your fingertips',
        icon: Icons.local_hospital_outlined,
      ),
      OnboardingPage(
        title: 'AI Insights & Recommendations',
        subtitle: 'Personalized clinical suggestions and optimization',
        icon: Icons.analytics_outlined,
      ),
      OnboardingPage(
        title: 'Smart Consumption Analytics',
        subtitle: 'Usage graphs and cost estimation visuals',
        icon: Icons.show_chart_outlined,
      ),
      OnboardingPage(
        title: 'Real-Time Monitoring',
        subtitle: 'Live calculations and clinical metrics',
        icon: Icons.monitor_heart_outlined,
      ),
      OnboardingPage(
        title: 'Voice Assistant',
        subtitle: 'Hands-free AI support and voice interactions',
        icon: Icons.mic_none_outlined,
      ),
      OnboardingPage(
        title: 'Safety Alerts',
        subtitle: 'Clinical risk detection and notifications',
        icon: Icons.warning_amber_outlined,
      ),
      OnboardingPage(
        title: 'Weight-Based Method',
        subtitle: 'Personalized dosage and weight-driven calculations',
        icon: Icons.fitness_center_outlined,
      ),
      OnboardingPage(
        title: 'Secure Medical Records',
        subtitle: 'Encrypted history and reliable record keeping',
        icon: Icons.folder_shared_outlined,
      ),
      OnboardingPage(
        title: 'Clinical Decision Support',
        subtitle: 'Optimize procedures with intelligent recommendations',
        icon: Icons.psychology_outlined,
      ),
      OnboardingPage(
        title: 'Resource & Cost Optimization',
        subtitle: 'Hospital resource management and savings',
        icon: Icons.account_balance_wallet_outlined,
      ),
      OnboardingPage(
        title: 'Modern Dashboard',
        subtitle: 'Beautiful modules and quick access to features',
        icon: Icons.dashboard_outlined,
      ),
      OnboardingPage(
        title: 'Get Started',
        subtitle: 'Thank you — start using the app to improve clinical care',
        icon: Icons.rocket_launch_outlined,
      ),
    ];

    _controller.addListener(() {
      final page = _controller.page ?? _controller.initialPage.toDouble();
      setState(() {
        _current = page.round();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < _pages.length - 1) {
      _controller.animateToPage(
        _current + 1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _skip() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 320),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }

  void _done() {
    // Navigate to home replacing onboarding so users don't return here
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: theme.colorScheme.primary,
        actions: [
          TextButton(
            onPressed: _skip,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return OnboardingPageWidget(page: page);
              },
            ),
          ),
          SafeArea(
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Flexible indicator area - scrolls if space is tight
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_pages.length, (i) {
                          final active = i == _current;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active ? theme.colorScheme.primary : theme.disabledColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Controls - keep minimal width to avoid overflow
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: _current > 0
                            ? () {
                                _controller.animateToPage(
                                  _current - 1,
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            : null,
                        child: const Text('Prev'),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 96, maxWidth: 140),
                        child: ElevatedButton(
                          onPressed: _current == _pages.length - 1 ? _done : _next,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            elevation: 6,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(_current == _pages.length - 1 ? 'Get Started' : 'Next'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
