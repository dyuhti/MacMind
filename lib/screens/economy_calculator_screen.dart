import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/app_header.dart';
import '../widgets/macmind_design.dart';
import 'profile_screen.dart';

/// Economy Calculator Screen
/// Interactive cost analysis for a single anesthetic agent
class EconomyCalculatorScreen extends StatefulWidget {
  const EconomyCalculatorScreen({super.key});

  @override
  State<EconomyCalculatorScreen> createState() =>
      _EconomyCalculatorScreenState();
}

class _EconomyCalculatorScreenState extends State<EconomyCalculatorScreen> {
  late TextEditingController _durationController;
  double _surgeryDuration = 60;
  String _selectedAgent = "Isoflurane";

  // Anesthetic agents data model
  final Map<String, Map<String, dynamic>> agents = {
    "Isoflurane": {"color": Colors.blue, "factor": 1.0},
    "Sevoflurane": {"color": Colors.green, "factor": 1.1},
    "Desflurane": {"color": Colors.purple, "factor": 1.2},
    "Halothane": {"color": Colors.orange, "factor": 1.3},
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
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  /// Calculate consumption based on FGF, duration, and agent factor
  double _calculateConsumption(
      double fgf, double duration, double agentFactor) {
    if (fgf == 0) return 0;
    return fgf * duration * agentFactor;
  }

  /// Generate line chart data for selected agent
  List<FlSpot> _generateConsumptionData() {
    final selected = agents[_selectedAgent];
    if (selected == null) return [];

    double agentFactor = selected['factor'];

    return fgfValues
        .asMap()
        .entries
        .map((entry) {
          double fgf = entry.value;
          double consumption =
              _calculateConsumption(fgf, _surgeryDuration, agentFactor);
          return FlSpot(fgf, consumption);
        })
        .toList();
  }

  /// Get maximum consumption for Y-axis scaling
  double _getMaxConsumption() {
    final selected = agents[_selectedAgent];
    if (selected == null) return 100;

    double agentFactor = selected['factor'];
    double max = 0;

    for (double fgf in fgfValues) {
      double consumption =
          _calculateConsumption(fgf, _surgeryDuration, agentFactor);
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
      // Parse duration, default to 60 if invalid
      _surgeryDuration = double.tryParse(value) ?? 60;
      if (_surgeryDuration <= 0) {
        _surgeryDuration = 60;
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
                      'Tap any point on the graph to see detailed values. Consumption is calculated as: FGF × Duration × Agent Factor',
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

  /// Build consumption analysis card with single line chart
  Widget _buildConsumptionAnalysisCard() {
    double maxConsumption = _getMaxConsumption();
    final selected = agents[_selectedAgent];
    final selectedColor = selected?['color'] ?? Colors.blue;

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
            Text(
              'Duration: ${_surgeryDuration.toStringAsFixed(0)} min',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
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
                        'Consumption',
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
                            'FGF: ${spot.x.toStringAsFixed(2)} L/min\nConsumption: ${spot.y.toStringAsFixed(1)}',
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
          ],
        ),
      ),
    );
  }
}


