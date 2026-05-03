import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../widgets/app_header.dart';
import '../widgets/macmind_design.dart';
import 'profile_screen.dart';

/// Economy Calculator Screen
/// Clinically accurate anesthetic consumption calculator using molecular weight-based formula
class EconomyCalculatorScreen extends StatefulWidget {
  const EconomyCalculatorScreen({super.key});

  @override
  State<EconomyCalculatorScreen> createState() =>
      _EconomyCalculatorScreenState();
}

class _EconomyCalculatorScreenState extends State<EconomyCalculatorScreen> {
  late final TextEditingController _durationController;
  late final TextEditingController _concentrationController;

  double _surgeryDuration = 60;
  double _concentration = 2.0;
  String _selectedAgent = 'Isoflurane';

  final Map<String, Map<String, dynamic>> agents = {
    'Isoflurane': {'color': Colors.blue, 'mw': 184.5, 'k': 184.5 / 2412},
    'Sevoflurane': {'color': Colors.green, 'mw': 200.1, 'k': 200.1 / 2412},
    'Desflurane': {'color': Colors.purple, 'mw': 168.0, 'k': 168.0 / 2412},
    'Halothane': {'color': Colors.orange, 'mw': 197.4, 'k': 197.4 / 2412},
  };

  final List<double> fgfValues = [0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6];

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(text: '60');
    _concentrationController = TextEditingController(text: '2.0');
  }

  @override
  void dispose() {
    _durationController.dispose();
    _concentrationController.dispose();
    super.dispose();
  }

  double _calculateConsumption(
    double fgf,
    double concentration,
    double duration,
    double k,
  ) {
    if (fgf == 0 || concentration == 0 || duration == 0) return 0;
    return fgf * concentration * duration * k;
  }

  List<FlSpot> _generateConsumptionData() {
    final selected = agents[_selectedAgent];
    // Do not plot if duration is 0 or concentration is below minimum threshold
    if (selected == null || _surgeryDuration == 0 || _concentration < 0.1) {
      return [];
    }

    final double k = (selected['k'] as num).toDouble();
    return fgfValues
        .map(
          (fgf) => FlSpot(
            fgf,
            _calculateConsumption(fgf, _concentration, _surgeryDuration, k),
          ),
        )
        .toList();
  }

  void _updateDuration(String value) {
    setState(() {
      _surgeryDuration = double.tryParse(value) ?? 60;
    });
  }

  void _updateConcentration(String value) {
    setState(() {
      final parsed = double.tryParse(value);
      if (parsed == null || parsed.isNaN) {
        _concentration = 2.0;
      } else if (parsed <= 0) {
        _concentration = 0.1; // Minimum safe concentration
      } else if (parsed > 10) {
        _concentration = 10; // Maximum clinically realistic
      } else {
        _concentration = parsed;
      }
    });
  }

  void _updateAgent(String? value) {
    if (value == null) return;
    setState(() {
      _selectedAgent = value;
    });
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
              title: 'Economy Calculator',
              breadcrumb: 'Home • Volatile Anesthetic • Economy',
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
                  _buildDurationInputField(),
                  const SizedBox(height: 16),
                  _buildConcentrationInputField(),
                  const SizedBox(height: 20),
                  _buildAgentSelectorDropdown(),
                  const SizedBox(height: 24),
                  _buildConsumptionAnalysisCard(),
                  const SizedBox(height: 24),
                  const MacMindInfoCard(
                    icon: Icons.info_outline,
                    child: Text(
                      'Tap any point on the graph to see detailed values. Formula: Consumption (ml) = FGF × Concentration × Time × (MW / 2412)',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        height: 1.5,
                        color: MacMindColors.gray600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          child: MacMindBottomNav(
            selectedIndex: 0,
            onTap: (index) {
              if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDurationInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Surgery Duration (minutes)',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            onChanged: _updateDuration,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintText: 'Enter duration in minutes',
              hintStyle: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: Colors.black54,
              ),
              prefixIcon: const Icon(
                Icons.schedule_outlined,
                color: Colors.black38,
                size: 20,
              ),
            ),
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConcentrationInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Agent Concentration (%)',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _concentrationController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _updateConcentration,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintText: 'Enter concentration (e.g., 1–6%)',
              hintStyle: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: Colors.black54,
              ),
              prefixIcon: const Icon(
                Icons.opacity_outlined,
                color: Colors.black38,
                size: 20,
              ),
              suffixText: '%',
              suffixStyle: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        if (_concentration < 0.1) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Concentration must be at least 0.1%. Standard range is 1-6%.',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAgentSelectorDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Anesthetic Agent',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedAgent,
            onChanged: _updateAgent,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: const Icon(
                Icons.science_outlined,
                color: Colors.black38,
                size: 20,
              ),
            ),
            items: agents.keys
                .map(
                  (agent) => DropdownMenuItem<String>(
                    value: agent,
                    child: Text(
                      agent,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                )
                .toList(),
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              color: Colors.black87,
            ),
            dropdownColor: Colors.white,
            isExpanded: true,
          ),
        ),
      ],
    );
  }

  Widget _buildConsumptionAnalysisCard() {
    final dataPoints = _generateConsumptionData();
    // Calculate maximum Y value from data for dynamic scaling
    double maxY = dataPoints.isEmpty
      ? 1.0
      : dataPoints.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    // Calculate maximum X value so we can add right padding to avoid clipping
    final double maxXValue = dataPoints.isEmpty
      ? 6
      : dataPoints.map((e) => e.x).reduce((a, b) => a > b ? a : b);
    final double chartMaxX = maxXValue + 0.5;
    // Add 20% padding for visual breathing room
    maxY = maxY * 1.2;
    // Ensure minimum Y scale for small values
    if (maxY < 1) {
      maxY = 1;
    }
    // Use adaptive interval: smaller for small ranges, normal for larger
    final double interval = maxY < 10 ? maxY / 4 : maxY / 5;
    final selected = agents[_selectedAgent];
    final selectedColor = selected?['color'] as Color? ?? Colors.blue;
    final mw = (selected?['mw'] as num?)?.toDouble() ?? 184.5;
    final k = (selected?['k'] as num?)?.toDouble() ?? 0.076;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Consumption Analysis',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selectedColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _selectedAgent,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selectedColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Duration: ${_surgeryDuration.toStringAsFixed(0)} min',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  'Conc: ${_concentration.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selectedColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'MW: ${mw.toStringAsFixed(1)} g/mol | K: ${k.toStringAsFixed(4)}',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selectedColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 320,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 6,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: const Text(
                              'Consumption (ml)',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              horizontalInterval: maxY / 5,
                              verticalInterval: 1,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey.withValues(alpha: 0.2),
                                strokeWidth: 1,
                              ),
                              getDrawingVerticalLine: (value) => FlLine(
                                color: Colors.grey.withValues(alpha: 0.2),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 1 != 0) {
                                      return SideTitleWidget(axisSide: meta.axisSide, child: const SizedBox.shrink());
                                    }
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 11,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                axisNameWidget: const Text(
                                  'Fresh Gas Flow (L/min)',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                axisNameSize: 32,
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  interval: maxY / 5,
                                  getTitlesWidget: (value, meta) {
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text(
                                        value.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 11,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                axisNameWidget: const SizedBox.shrink(),
                                axisNameSize: 32,
                              ),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: const Border(
                                left: BorderSide(color: Colors.black, width: 2),
                                bottom: BorderSide(color: Colors.black, width: 2),
                                right: BorderSide.none,
                                top: BorderSide.none,
                              ),
                            ),
                            minX: 0,
                            maxX: chartMaxX,
                            minY: 0,
                            maxY: maxY,
                            clipData: FlClipData.none(),
                            lineBarsData: [
                              LineChartBarData(
                                spots: dataPoints,
                                isCurved: true,
                                color: selectedColor,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 5,
                                      color: selectedColor,
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(show: false),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                tooltipHorizontalAlignment: FLHorizontalAlignment.center,
                                maxContentWidth: 140,
                                tooltipMargin: 8,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    return LineTooltipItem(
                                      'FGF: ${spot.x.toStringAsFixed(1)}\n'
                                      'Cons: ${spot.y.toStringAsFixed(1)} ml',
                                      const TextStyle(
                                        fontFamily: 'DM Sans',
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


