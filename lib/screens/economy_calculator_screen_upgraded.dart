import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
  late TextEditingController _durationController;
  late TextEditingController _concentrationController;
  double _surgeryDuration = 60;
  double _concentration = 2.0;
  String _selectedAgent = "Isoflurane";

  // Clinically accurate agent data with molecular weights and K constants
  // K = Molecular Weight / 2412 (standard constant for anesthetic calculations)
  final Map<String, Map<String, dynamic>> agents = {
    "Isoflurane": {
      "color": Colors.blue,
      "mw": 184.5,
      "k": 184.5 / 2412,
    },
    "Sevoflurane": {
      "color": Colors.green,
      "mw": 200.1,
      "k": 200.1 / 2412,
    },
    "Desflurane": {
      "color": Colors.purple,
      "mw": 168.0,
      "k": 168.0 / 2412,
    },
    "Halothane": {
      "color": Colors.orange,
      "mw": 197.4,
      "k": 197.4 / 2412,
    },
  };

  // Fresh Gas Flow values (L/min)
  final List<double> fgfValues = [
    0,
    0.5,
    1,
    1.5,
    2,
    2.5,
    3,
    3.5,
    4,
    4.5,
    5,
    5.5,
    6
  ];

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

  /// Clinical consumption formula: Consumption (ml) = FGF × Concentration × Duration × K
  /// Where K = MW / 2412
  double _calculateConsumption(
      double fgf, double concentration, double duration, double k) {
    if (fgf == 0 || concentration == 0 || duration == 0) return 0;
    return fgf * (concentration / 100) * duration * k;
  }

  /// Generate line chart data for selected agent using clinical formula
  List<FlSpot> _generateConsumptionData() {
    final selected = agents[_selectedAgent];
    if (selected == null) return [];

    double k = selected['k'];

    return fgfValues
        .asMap()
        .entries
        .map((entry) {
          double fgf = entry.value;
          double consumption =
              _calculateConsumption(fgf, _concentration, _surgeryDuration, k);
          return FlSpot(fgf, consumption);
        })
        .toList();
  }

  /// Get maximum consumption for Y-axis scaling
  double _getMaxConsumption() {
    final selected = agents[_selectedAgent];
    if (selected == null) return 100;

    double k = selected['k'];
    double max = 0;

    for (double fgf in fgfValues) {
      double consumption =
          _calculateConsumption(fgf, _concentration, _surgeryDuration, k);
      if (consumption > max) {
        max = consumption;
      }
    }
    // Add 20% padding to max value
    return max * 1.2;
  }

  /// Update surgery duration and trigger UI rebuild
  void _updateDuration(String value) {
    setState(() {
      _surgeryDuration = double.tryParse(value) ?? 60;
      if (_surgeryDuration <= 0) {
        _surgeryDuration = 60;
      }
    });
  }

  /// Update concentration and trigger UI rebuild
  void _updateConcentration(String value) {
    setState(() {
      _concentration = double.tryParse(value) ?? 2.0;
      if (_concentration <= 0) {
        _concentration = 2.0;
      }
      // Clamp to realistic anesthetic concentration range
      if (_concentration > 10) {
        _concentration = 10;
      }
    });
  }

  /// Update selected agent and trigger UI rebuild
  void _updateAgent(String? value) {
    if (value != null && agents.containsKey(value)) {
      setState(() {
        _selectedAgent = value;
      });
    }
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
                  // Duration Input Field
                  _buildDurationInputField(),
                  const SizedBox(height: 16),
                  // Concentration Input Field
                  _buildConcentrationInputField(),
                  const SizedBox(height: 20),
                  // Agent Selector Dropdown
                  _buildAgentSelectorDropdown(),
                  const SizedBox(height: 24),
                  // Consumption Analysis Card
                  _buildConsumptionAnalysisCard(),
                  const SizedBox(height: 24),
                  // Info Card
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

  /// Build duration input field
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

  /// Build concentration input field
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
      ],
    );
  }

  /// Build agent selector dropdown
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
                .map((agent) => DropdownMenuItem<String>(
                      value: agent,
                      child: Text(
                        agent,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ))
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

  /// Build consumption analysis card with clinical formula graph
  Widget _buildConsumptionAnalysisCard() {
    double maxConsumption = _getMaxConsumption();
    final selected = agents[_selectedAgent];
    final selectedColor = selected?['color'] ?? Colors.blue;
    final mw = selected?['mw'] ?? 184.5;
    final k = selected?['k'] ?? 0.076;

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
            // Title and Agent Badge
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

            // Clinical Parameters Display
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

            // Agent Info: Molecular Weight and K constant
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

            // Line Chart
            SizedBox(
              height: 320,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: const Color(0xFFE5E7EB),
                        strokeWidth: 0.8,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: const Color(0xFFE5E7EB),
                        strokeWidth: 0.8,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              value.toStringAsFixed(1),
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
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
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              value.toStringAsFixed(0),
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                      axisNameWidget: const Text(
                        'Consumption (ml)',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      axisNameSize: 32,
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: maxConsumption,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateConsumptionData(),
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
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            'FGF: ${spot.x.toStringAsFixed(2)} L/min\n'
                            'Conc: ${_concentration.toStringAsFixed(1)}%\n'
                            'Time: ${_surgeryDuration.toStringAsFixed(0)} min\n'
                            'Consumption: ${spot.y.toStringAsFixed(2)} ml',
                            const TextStyle(
                              fontFamily: 'DM Sans',
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Formula Label
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Formula: Consumption (ml) = FGF × Concentration × Time × (MW / 2412)',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
