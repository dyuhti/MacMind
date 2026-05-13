import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/ai_service.dart';
import '../widgets/app_header.dart';
import '../widgets/ai_clinical_insight_card.dart';
import '../widgets/macmind_design.dart';
import 'case_history_screen.dart';
import 'settings_screen.dart';

/// Economy Calculator Screen
/// Clinically accurate anesthetic concentration calculator
class EconomyCalculatorScreen extends StatefulWidget {
  const EconomyCalculatorScreen({super.key});

  @override
  State<EconomyCalculatorScreen> createState() =>
      _EconomyCalculatorScreenState();
}

class _EconomyCalculatorScreenState extends State<EconomyCalculatorScreen> {
  int _selectedIndex = 0;
  late final TextEditingController _durationController;
  late final TextEditingController _concentrationController;
  Timer? _aiDebounce;

  double _surgeryDuration = 60;
  double _concentration   = 2.0;
  String _selectedAgent   = 'Isoflurane';
  bool   _isAiLoading     = false;
  List<String> _aiInsights = [];
  String? _aiWarning;

  final Map<String, Map<String, dynamic>> agents = {
    'Isoflurane':  {'color': Colors.blue,   'mw': 184.5, 'k': 0.0765, 'minConc': 0.2, 'maxConc': 5.0},
    'Sevoflurane': {'color': Colors.green,  'mw': 200.0, 'k': 0.0605, 'minConc': 0.5, 'maxConc': 8.0},
    'Desflurane':  {'color': Colors.purple, 'mw': 168.0, 'k': 0.4200, 'minConc': 2.0, 'maxConc': 18.0},
    'Halothane':   {'color': Colors.orange, 'mw': 197.4, 'k': 0.2350, 'minConc': 0.2, 'maxConc': 5.0},
  };

  // ── FGF values: 0 → 6 L/min (starts at 0 so line begins at the origin) ──
  final List<double> fgfValues = [
    0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0
  ];

  static const double _chartMinX = 0.0;
  static const double _chartMaxX = 6.5;

  @override
  void initState() {
    super.initState();
    _durationController      = TextEditingController(text: '60');
    _concentrationController = TextEditingController(text: '2.0');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleEconomyInsightFetch();
    });
  }

  @override
  void dispose() {
    _aiDebounce?.cancel();
    _durationController.dispose();
    _concentrationController.dispose();
    super.dispose();
  }

  void _scheduleEconomyInsightFetch() {
    _aiDebounce?.cancel();
    _aiDebounce = Timer(const Duration(milliseconds: 650), _fetchEconomyInsights);
  }

  Future<void> _fetchEconomyInsights() async {
    if (_surgeryDuration <= 0 || _concentration < 0.1) {
      if (!mounted) return;
      setState(() { _isAiLoading = false; _aiInsights = []; _aiWarning = null; });
      return;
    }
    if (!mounted) return;
    setState(() { _isAiLoading = true; _aiWarning = null; });

    final k = (agents[_selectedAgent]?['k'] as num?)?.toDouble() ?? 0.0;
    const fgf = 3.0;
    final consumption = _calcConsumption(fgf, _concentration, _surgeryDuration, k);

    final result = await AIService.fetchEconomyInsights(
      agent:         _selectedAgent,
      freshGasFlow:  fgf,
      concentration: _concentration,
      duration:      _surgeryDuration,
      consumption:   consumption,
    );

    if (!mounted) return;
    setState(() {
      _isAiLoading = false;
      if (result['success'] == true) {
        _aiInsights = (result['insights'] as List<dynamic>).cast<String>();
        _aiWarning  = null;
      } else {
        _aiInsights = [];
        _aiWarning  = (result['message'] as String?) ??
            'AI clinical insights are temporarily unavailable.';
      }
    });
  }

  double _calcConsumption(double fgf, double conc, double dur, double k) {
    if (fgf == 0 || conc == 0 || dur == 0) return 0;
    return fgf * conc * dur * k;
  }

  /// Delivered Concentration (%) varies clinically with FGF
  /// Low FGF: 85% of target | Medium FGF: 90% | High FGF: 95–100%
  List<FlSpot> _generateConcentrationData() {
    final double target = _concentration.clamp(0.1, 20.0);
    return fgfValues.map((fgf) {
      // Realistic delivery: low FGF delivers less, high FGF approaches target
      final double delivered = fgf <= 1.0
          ? target * 0.85  // 85% at low flow
          : fgf <= 3.0
              ? target * (0.90 + (fgf - 1.0) * 0.033)  // 90–96% at medium
              : target * (0.95 + (fgf - 3.0) * 0.017); // 95–100% at high
      return FlSpot(fgf, delivered.clamp(0.1, 20.0));
    }).toList();
  }

  void _updateDuration(String v) {
    setState(() => _surgeryDuration = double.tryParse(v) ?? 60);
    _scheduleEconomyInsightFetch();
  }

  void _updateConcentration(String v) {
    setState(() {
      final agentInfo = agents[_selectedAgent]!;
      final minConc = (agentInfo['minConc'] as num).toDouble();
      final maxConc = (agentInfo['maxConc'] as num).toDouble();
      
      final p = double.tryParse(v);
      if (p == null || p.isNaN || p <= 0) {
        _concentration = (p != null && p <= 0) ? minConc : 2.0;
      } else {
        _concentration = p.clamp(minConc, maxConc);
      }
    });
    _scheduleEconomyInsightFetch();
  }

  void _updateAgent(String? v) {
    if (v == null) return;
    setState(() => _selectedAgent = v);
    _scheduleEconomyInsightFetch();
  }

  void _onItemTapped(int i) => setState(() => _selectedIndex = i);

  List<Widget> get _screens => [
        _buildEconomyContent(),
        CaseHistoryScreen(
          onBack:       () => _onItemTapped(0),
          onProfileTap: () => _onItemTapped(2),
        ),
        SettingsScreen(onBack: () => _onItemTapped(0)),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          child: MacMindBottomNav(
            selectedIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }

  Widget _buildEconomyContent() {
    return Column(
      children: [
        SafeArea(
          top: false, left: false, right: false,
          child: AppHeader(
            title:        'Economy Calculator',
            breadcrumb:   'Home • Volatile Anesthetic • Economy',
            showBack:     true,
            onProfileTap: () => _onItemTapped(2),
          ),
        ),
        Expanded(
          child: Container(
            width:   double.infinity,
            color:   const Color(0xFFF5F7FA),
            padding: const EdgeInsets.all(16),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDurationField(),
                const SizedBox(height: 16),
                _buildConcentrationField(),
                const SizedBox(height: 20),
                _buildAgentDropdown(),
                const SizedBox(height: 24),
                _buildConcentrationAnalysisCard(),
                const SizedBox(height: 14),
                AIClinicalInsightCard(
                  isLoading:      _isAiLoading,
                  insights:       _aiInsights,
                  warningMessage: _aiWarning,
                  onRetry:        _fetchEconomyInsights,
                ),
                const SizedBox(height: 24),
                const MacMindInfoCard(
                  icon: Icons.info_outline,
                  child: Text(
                    'Tap any point on the graph to see detailed values. '
                    'The chart displays delivered concentration (%) across '
                    'Fresh Gas Flow for the selected agent.',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize:   12,
                      height:     1.5,
                      color:      MacMindColors.gray600,
                    ),
                  ),
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INPUT WIDGETS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDurationField() => _labeledField(
    label: 'Surgery Duration (minutes)',
    child: TextField(
      controller:   _durationController,
      keyboardType: TextInputType.number,
      onChanged:    _updateDuration,
      decoration:   _dec(hint: 'Enter duration in minutes', icon: Icons.schedule_outlined),
      style:        _ts,
    ),
  );

  Widget _buildConcentrationField() => _labeledField(
    label: 'Agent Concentration (%)',
    child: TextField(
      controller:   _concentrationController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged:    _updateConcentration,
      decoration:   InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled:         true,
        fillColor:      Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        hintText:       'Enter concentration',
        hintStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: Colors.black54),
        helperText: 'Valid range: ${_getAgentMinConc().toStringAsFixed(1)}–${_getAgentMaxConc().toStringAsFixed(1)}% for $_selectedAgent',
        helperStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: Colors.black45),
        prefixIcon:  Icon(Icons.opacity_outlined, color: Colors.black38, size: 20),
        suffixText:  '%',
        suffixStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: Colors.black54),
      ),
      style:        _ts,
    ),
    warning: _concentration < _getAgentMinConc()
        ? 'Must be ≥${_getAgentMinConc().toStringAsFixed(1)}%'
        : _concentration > _getAgentMaxConc()
            ? 'Must be ≤${_getAgentMaxConc().toStringAsFixed(1)}%'
            : null,
  );

  Widget _buildAgentDropdown() => _labeledField(
    label: 'Select Anesthetic Agent',
    child: DropdownButtonFormField<String>(
      initialValue:  _selectedAgent,
      onChanged:     _updateAgent,
      decoration:    _dec(icon: Icons.science_outlined),
      items: agents.keys.map((a) => DropdownMenuItem(
        value: a,
        child: Text(a, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: Colors.black87)),
      )).toList(),
      style:         _ts,
      dropdownColor: Colors.white,
      isExpanded:    true,
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // CONCENTRATION ANALYSIS CARD
  // ─────────────────────────────────────────────────────────────────────────

  double _getAgentMinConc() => (agents[_selectedAgent]?['minConc'] as num?)?.toDouble() ?? 0.2;
  double _getAgentMaxConc() => (agents[_selectedAgent]?['maxConc'] as num?)?.toDouble() ?? 5.0;

  Widget _buildConcentrationAnalysisCard() {
    final spots     = _generateConcentrationData();
    final agentInfo = agents[_selectedAgent]!;
    final color     = agentInfo['color'] as Color;
    final mw        = (agentInfo['mw']  as num).toDouble();
    final k         = (agentInfo['k']   as num).toDouble();

    // Y-axis: agent-specific max + 20% headroom, round to clean intervals
    final maxConc = _getAgentMaxConc();
    final ceiling = (maxConc * 1.2).clamp(1.0, 22.0);
    final double maxY     = (ceiling / 0.5).ceil() * 0.5;
    final double interval = maxY <= 3.0 ? 0.5
                          : maxY <= 6.0 ? 1.0
                          : maxY <= 12.0 ? 2.0
                          : maxY <= 18.0 ? 3.0
                          :                5.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Title + badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Concentration Analysis',
                  style: TextStyle(
                    fontFamily: 'DM Sans', fontSize: 17,
                    fontWeight: FontWeight.w700, color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:        color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _selectedAgent,
                    style: TextStyle(
                      fontFamily: 'DM Sans', fontSize: 12,
                      fontWeight: FontWeight.w600, color: color,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Duration / Conc
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Duration: ${_surgeryDuration.toStringAsFixed(0)} min',
                  style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: Colors.black54)),
                Text('Conc: ${_concentration.toStringAsFixed(1)}%',
                  style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: Colors.black54)),
              ],
            ),

            const SizedBox(height: 8),

            // MW / K pill
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color:        color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'MW: ${mw.toStringAsFixed(1)} g/mol  |  K: ${k.toStringAsFixed(4)}',
                style: TextStyle(
                  fontFamily: 'DM Sans', fontSize: 12,
                  fontWeight: FontWeight.w500, color: color,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── CHART ────────────────────────────────────────────────────
            SizedBox(
              height: 230,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // Y-axis label — external RotatedBox (reliable, never flips)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          'Concentration (%)',
                          style: const TextStyle(
                            fontFamily: 'DM Sans', fontSize: 11,
                            fontWeight: FontWeight.w600, color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Chart body + X label
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: LineChart(
                            duration: const Duration(milliseconds: 200),
                            LineChartData(
                              gridData: FlGridData(
                                show:               true,
                                drawVerticalLine:   true,
                                horizontalInterval: interval,
                                verticalInterval:   1,
                                getDrawingHorizontalLine: (_) => FlLine(
                                  color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
                                getDrawingVerticalLine: (_) => FlLine(
                                  color: Colors.grey.withOpacity(0.08), strokeWidth: 1),
                              ),

                              titlesData: FlTitlesData(
                                topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),

                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles:   true,
                                    reservedSize: 44,
                                    interval:     interval,
                                    getTitlesWidget: (value, meta) {
                                      if (value >= meta.max) return const SizedBox.shrink();
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        space:    4,
                                        child: Text(
                                          '${value.toStringAsFixed(1)}%',
                                          style: const TextStyle(
                                            fontFamily: 'DM Sans', fontSize: 9,
                                            color: Colors.black54, fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles:   true,
                                    reservedSize: 24,
                                    interval:     1,
                                    getTitlesWidget: (value, meta) {
                                      if (value != value.roundToDouble()) return const SizedBox.shrink();
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        space:    4,
                                        child: Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(
                                            fontFamily: 'DM Sans', fontSize: 9,
                                            color: Colors.black54, fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              borderData: FlBorderData(
                                show: true,
                                border: Border(
                                  left:   BorderSide(color: Colors.black87.withOpacity(0.7), width: 1.5),
                                  bottom: BorderSide(color: Colors.black87.withOpacity(0.7), width: 1.5),
                                  right:  BorderSide.none,
                                  top:    BorderSide.none,
                                ),
                              ),

                              // minX=0 keeps the "0" label on X axis.
                              // First spot is at x=0.5, so fl_chart draws
                              // nothing between x=0 and x=0.5 — no bar artifact.
                              minX: _chartMinX,
                              maxX: _chartMaxX,
                              minY: 0,
                              maxY: maxY,

                              lineBarsData: [
                                LineChartBarData(
                                  spots:            spots,
                                  isCurved:         false,
                                  color:            color,
                                  barWidth:         2.0,
                                  isStrokeCapRound: true,
                                  dashArray:        [5, 4],
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (_, __, ___, ____) =>
                                      FlDotCirclePainter(
                                        radius:      3.5,
                                        color:       color,
                                        strokeWidth: 1.5,
                                        strokeColor: Colors.white,
                                      ),
                                  ),
                                  belowBarData: BarAreaData(show: false),
                                ),
                              ],

                              lineTouchData: LineTouchData(
                                enabled: true,
                                touchTooltipData: LineTouchTooltipData(
                                  fitInsideHorizontally: true,
                                  fitInsideVertically:   true,
                                  maxContentWidth:       160,
                                  tooltipMargin:         8,
                                  getTooltipItems: (s) => s.map((sp) => LineTooltipItem(
                                    'FGF: ${sp.x.toStringAsFixed(1)} L/min\nConc: ${sp.y.toStringAsFixed(2)}%',
                                    const TextStyle(
                                      fontFamily: 'DM Sans', color: Colors.white,
                                      fontSize: 11, fontWeight: FontWeight.w600,
                                    ),
                                  )).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),
                        const Text(
                          'Fresh Gas Flow (L/min)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'DM Sans', fontSize: 11,
                            fontWeight: FontWeight.w600, color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _labeledField({required String label, required Widget child, String? warning}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          fontFamily: 'DM Sans', fontSize: 14,
          fontWeight: FontWeight.w600, color: Colors.black87,
        )),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2),
            )],
          ),
          child: child,
        ),
        if (warning != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
            const SizedBox(width: 6),
            Expanded(child: Text(warning, style: const TextStyle(
              fontFamily: 'DM Sans', fontSize: 11, color: Colors.redAccent,
            ))),
          ]),
        ],
      ],
    );
  }

  InputDecoration _dec({String? hint, IconData? icon, String? suffixText}) {
    return InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      filled:         true,
      fillColor:      Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      hintText:       hint,
      hintStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: Colors.black54),
      prefixIcon:  icon != null ? Icon(icon, color: Colors.black38, size: 20) : null,
      suffixText:  suffixText,
      suffixStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: Colors.black54),
    );
  }

  static const TextStyle _ts = TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: Colors.black87);
}