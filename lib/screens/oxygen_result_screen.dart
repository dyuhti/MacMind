import 'package:flutter/material.dart';

import '../services/ai_service.dart';
import '../widgets/ai_clinical_insight_card.dart';
import '../widgets/app_header.dart';
import '../widgets/custom_button.dart' show SecondaryButton;
import 'oxygen_consumption_table_screen.dart';
import 'settings_screen.dart';

class OxygenResultScreen extends StatefulWidget {
  final String cylinderType;
  final double pressure;
  final double factor;
  final double totalContent;

  const OxygenResultScreen({
    super.key,
    required this.cylinderType,
    required this.pressure,
    required this.factor,
    required this.totalContent,
  });

  @override
  State<OxygenResultScreen> createState() => _OxygenResultScreenState();
}

class _OxygenResultScreenState extends State<OxygenResultScreen> {
  bool _isInitialLoading = true;
  bool _isAiLoading = false;
  List<String> _aiInsights = [];
  String? _aiWarning;

  static const List<String> _fallbackInsights = [
    'Available oxygen reserve is suitable for short-duration procedures.',
    'Cylinder pressure is adequate for routine planning.',
    'Maintaining moderate flow settings improves oxygen efficiency.',
    'Use this estimate alongside bedside clinical monitoring.',
  ];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await Future.wait<void>([
      _fetchOxygenInsights(),
      Future<void>.delayed(const Duration(milliseconds: 420)),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _isInitialLoading = false;
    });
  }

  Future<void> _fetchOxygenInsights() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isAiLoading = true;
      _aiWarning = null;
    });

    final result = await AIService.fetchOxygenInsights(
      cylinderType: widget.cylinderType,
      pressure: widget.pressure,
      oxygenContent: widget.totalContent,
      factor: widget.factor,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isAiLoading = false;
      if (result['success'] == true) {
        _aiInsights = (result['insights'] as List<dynamic>).cast<String>();
      } else {
        _aiInsights = [];
        _aiWarning = (result['message'] as String?) ??
            'AI clinical insights are temporarily unavailable.';
      }
    });
  }

  void _openConsumptionTable() {
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (context, animation, secondaryAnimation) {
          return OxygenConsumptionTableScreen(totalContent: widget.totalContent);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slideAnimation, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FB),
      body: Column(
        children: [
          SafeArea(
            top: false,
            left: false,
            right: false,
            child: AppHeader(
              title: 'Oxygen Cylinder Results',
              subtitle: 'Calculated from pressure and selected cylinder',
              breadcrumb: 'Input • Results',
              showBack: true,
              onBack: () => Navigator.pop(context),
              onProfileTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: _isInitialLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0A4D8C),
                      ),
                    )
                  : ListView(
                      key: const ValueKey<String>('oxygen-results-content'),
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildTotalOxygenCard(),
                        const SizedBox(height: 12),
                        _buildBreakdownCard(),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: SecondaryButton(
                            label: 'View Consumption Table',
                            onPressed: _openConsumptionTable,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AIClinicalInsightCard(
                          isLoading: _isAiLoading,
                          insights: _aiInsights.isEmpty ? _fallbackInsights : _aiInsights,
                          warningMessage: _aiWarning,
                          onRetry: _fetchOxygenInsights,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalOxygenCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE5F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0A4D8C),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety_outlined, size: 20, color: Color(0xFF0A4D8C)),
              SizedBox(width: 8),
              Text(
                'Total Oxygen Content',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF425466),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${widget.totalContent.toStringAsFixed(1)} L',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F6E56),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cylinder: ${widget.cylinderType}',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calculation Breakdown',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A4D8C),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.pressure.toStringAsFixed(1)} PSI x ${widget.factor.toStringAsFixed(2)} = ${widget.totalContent.toStringAsFixed(1)} L',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
