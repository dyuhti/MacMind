import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/app_header.dart';
import '../widgets/custom_button.dart' show PrimaryButton, SecondaryButton;
import 'profile_screen.dart';

/// Screen B: Oxygen Cylinder Module
/// Calculates total oxygen content from pressure and cylinder type.
class OxygenCylinderModuleScreen extends StatefulWidget {
  const OxygenCylinderModuleScreen({super.key});

  @override
  State<OxygenCylinderModuleScreen> createState() => _OxygenCylinderModuleScreenState();
}

class _OxygenCylinderModuleScreenState extends State<OxygenCylinderModuleScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _pressureController = TextEditingController();

  static const Map<String, double> _cylinderFactors = {
    'A Cylinder': 0.08,
    'B Cylinder': 0.16,
    'C Cylinder': 0.28,
    'D Cylinder': 0.16,
    'E Cylinder': 0.28,
    'F Cylinder': 0.85,
    'G Cylinder': 2.41,
    'H Cylinder': 3.14,
  };

  static const List<String> _cylinderOrder = [
    'A Cylinder',
    'B Cylinder',
    'C Cylinder',
    'D Cylinder',
    'E Cylinder',
    'F Cylinder',
    'G Cylinder',
    'H Cylinder',
  ];

  String? _selectedCylinderType = 'A Cylinder';
  double? _totalContent;
  double? _lastPressure;
  double? _lastFactor;

  @override
  void dispose() {
    _pressureController.dispose();
    super.dispose();
  }

  double get _selectedFactor => _cylinderFactors[_selectedCylinderType] ?? 0.0;

  void _calculateTotalContent() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final pressure = double.parse(_pressureController.text.trim());
    final factor = _selectedFactor;

    // DEBUG LOGGING - IMPORTANT FOR TESTING
    print('\n========== OXYGEN CYLINDER CALCULATION ==========');
    print('Cylinder: $_selectedCylinderType');
    print('Pressure: $pressure PSI');
    print('Factor: $factor');
    final totalContent = pressure * factor;
    print('Total Content: $totalContent L');
    print('Formula: $pressure × $factor = $totalContent L');
    print('================================================\n');

    setState(() {
      _totalContent = totalContent;
      _lastPressure = pressure;
      _lastFactor = factor;
    });
  }

  void _openConsumptionTable() {
    final totalContent = _totalContent;
    if (totalContent == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsumptionTableScreen(totalContent: totalContent),
      ),
    );
  }

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
              title: 'Oxygen Cylinder Duration',
              breadcrumb: 'Home • Oxygen Cylinder Module',
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
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildIntroCard(),
                const SizedBox(height: 20),
                _buildInputCard(),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Calculate',
                  onPressed: _calculateTotalContent,
                ),
                if (_totalContent != null) ...[
                  const SizedBox(height: 16),
                  _buildResultCard(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Text(
        'Enter cylinder pressure and select the cylinder type. The factor is assigned automatically to calculate total oxygen content.',
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 13,
          height: 1.5,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cylinder Inputs',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: Color(0xFF888780),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedCylinderType,
              isExpanded: true,
              decoration: _inputDecoration(
                label: 'Cylinder Type',
                icon: Icons.medical_services_outlined,
              ),
              items: _cylinderOrder
                  .map(
                    (type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCylinderType = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a cylinder type';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pressureController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*$'))],
              decoration: _inputDecoration(
                label: 'Pressure (PSI)',
                hintText: 'e.g., 2000–2200',
                icon: Icons.speed,
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'Pressure is required';
                }
                final pressure = double.tryParse(text);
                if (pressure == null || pressure <= 0) {
                  return 'Enter a valid pressure greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter pressure in PSI (e.g., 2000–2200). Formula: Total Content (L) = Pressure (PSI) × Cylinder Factor',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                height: 1.4,
                color: Color(0xFF333333),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Auto factor: ${_selectedFactor.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D9E75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final totalContent = _totalContent ?? 0;
    final pressure = _lastPressure ?? 0;
    final factor = _lastFactor ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Oxygen Content',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5F5E5A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${totalContent.toStringAsFixed(1)} L',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F6E56),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F8F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD1E8E0)),
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
                    color: Color(0xFF0F6E56),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${pressure.toStringAsFixed(1)} PSI × $factor = ${totalContent.toStringAsFixed(1)} L',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              label: 'View Consumption Table',
              onPressed: _openConsumptionTable,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF185FA5)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF185FA5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
    );
  }
}

class ConsumptionTableScreen extends StatefulWidget {
  final double totalContent;

  const ConsumptionTableScreen({super.key, required this.totalContent});

  @override
  State<ConsumptionTableScreen> createState() => _ConsumptionTableScreenState();
}

class _ConsumptionTableScreenState extends State<ConsumptionTableScreen>
    with WidgetsBindingObserver {
  int selectedIndex = -1;
  Timer? _countdownTimer;
  int _remainingTime = 0;
  int _totalDurationSeconds = 0;
  int _warningAtElapsedSeconds = -1;
  bool _isTimerRunning = false;
  bool _warningShown = false;
  bool _finalShown = false;
  int? _selectedFlowRate;
  int? _activeRowIndex;

  // DateTime-based tracking for background timer accuracy
  DateTime? _timerStartTime;
  int? _timerDurationSeconds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Handle app resume to recalculate remaining time (app was in background)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isTimerRunning) {
      print('⏱ App resumed. Recalculating remaining time...');
      _recalculateRemainingTime();
    }
  }

  /// Recalculate remaining time based on elapsed real-world time
  void _recalculateRemainingTime() {
    if (_timerStartTime == null || _timerDurationSeconds == null) {
      return;
    }

    final elapsed = DateTime.now().difference(_timerStartTime!).inSeconds;
    final newRemaining = _timerDurationSeconds! - elapsed;

    setState(() {
      _remainingTime = newRemaining > 0 ? newRemaining : 0;
    });

    if (_remainingTime <= 0) {
      _handleTimerCompletion();
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _showRowActionSheet(_ConsumptionRowData row, int index) async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flow Rate: ${row.flowRate} L/min',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Duration: ${row.durationMin.toStringAsFixed(2)} min',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext, 'start'),
                    child: const Text('Start Timer'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext, 'cancel'),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selection != 'start') {
      return;
    }

    _startTimer(row: row, index: index);
  }

  void _startTimer({required _ConsumptionRowData row, required int index}) {
    final durationInSeconds = (row.durationMin * 60).round();
    if (durationInSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duration must be greater than 0 seconds')),
      );
      return;
    }

    if (_isTimerRunning && _activeRowIndex == index) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timer is already running for this row')),
      );
      return;
    }

    _countdownTimer?.cancel();

    final warningTime = durationInSeconds - (5 * 60);
    final hasWarningWindow = durationInSeconds >= 300;

    // Store start time for background timer accuracy
    final now = DateTime.now();

    setState(() {
      _totalDurationSeconds = durationInSeconds;
      _remainingTime = durationInSeconds;
      _warningAtElapsedSeconds = warningTime;
      _isTimerRunning = true;
      _warningShown = false;
      _finalShown = false;
      _selectedFlowRate = row.flowRate;
      _activeRowIndex = index;
      _timerStartTime = now;
      _timerDurationSeconds = durationInSeconds;
    });

    // If total duration < 5 minutes, skip warning
    if (!hasWarningWindow) {
      _warningShown = true;
      print('ℹ️ Duration < 5 minutes: warning skipped');
    }

    // Start periodic UI update timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _recalculateRemainingTime();
      _checkAlertTriggers();
    });

    print(
      '⏱ Timer started: ${_totalDurationSeconds}s | Flow: ${row.flowRate} L/min',
    );
  }

  void _checkAlertTriggers() {
    if (_timerStartTime == null) {
      return;
    }

    final elapsedSeconds = DateTime.now().difference(_timerStartTime!).inSeconds;

    // Check 5-minute warning
    if (!_warningShown &&
        _warningAtElapsedSeconds >= 0 &&
        elapsedSeconds >= _warningAtElapsedSeconds &&
        _totalDurationSeconds >= 300) {
      _warningShown = true;
      print('⚠️ 5-minute warning triggered');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Oxygen will run out in 5 minutes'),
          duration: Duration(seconds: 4),
        ),
      );
    }

    // Check final depletion
    if (!_finalShown && _remainingTime <= 0) {
      _handleTimerCompletion();
    }
  }

  void _handleTimerCompletion() {
    _finalShown = true;
    _countdownTimer?.cancel();

    setState(() {
      _remainingTime = 0;
      _isTimerRunning = false;
    });

    print('🚨 Timer completed: oxygen supply exhausted');
    _showFinalAlert();
  }

  void _showFinalAlert() {
    if (!mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Oxygen Alert'),
          content: const Text('🚨 Oxygen supply exhausted'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _resetTimer();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _resetTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _remainingTime = 0;
      _totalDurationSeconds = 0;
      _warningAtElapsedSeconds = -1;
      _isTimerRunning = false;
      _warningShown = false;
      _finalShown = false;
      _selectedFlowRate = null;
      _activeRowIndex = null;
      _timerStartTime = null;
      _timerDurationSeconds = null;
      selectedIndex = -1;
    });
    print('🔄 Timer reset');
  }
  Widget build(BuildContext context) {
    final rows = List.generate(15, (index) {
      final flowRate = index + 1;
      final durationMin = widget.totalContent / flowRate;
      final durationHr = durationMin / 60;
      return _ConsumptionRowData(
        flowRate: flowRate,
        durationMin: durationMin,
        durationHr: durationHr,
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          SafeArea(
            top: false,
            left: false,
            right: false,
            child: AppHeader(
              title: 'Oxygen Consumption Table',
              subtitle: 'Total content: ${widget.totalContent.toStringAsFixed(1)} L',
              breadcrumb: _isTimerRunning ? '⏱ Timer running in background' : 'Tap a row to highlight',
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
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Oxygen Consumption Table',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: Color(0xFF888780),
                        ),
                      ),
                      if (_isTimerRunning) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF8EF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCDE8D7)),
                          ),
                          child: Text(
                            'Time Remaining: ${_formatDuration(_remainingTime)} | Flow: ${_selectedFlowRate ?? '-'} L/min',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildHeaderRow(),
                      const SizedBox(height: 8),
                      ...List.generate(rows.length, (index) {
                        final row = rows[index];
                        final isSelected = index == selectedIndex;
                        final isActiveTimerRow = _isTimerRunning && _activeRowIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: isActiveTimerRow
                                ? Colors.green.withOpacity(0.2)
                                : isSelected
                                    ? Colors.blue.withOpacity(0.2)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  selectedIndex = index;
                                });
                                _showRowActionSheet(row, index);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${row.flowRate}',
                                        style: const TextStyle(fontFamily: 'DM Sans'),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        row.durationMin.toStringAsFixed(2),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontFamily: 'DM Sans'),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        row.durationHr.toStringAsFixed(2),
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(fontFamily: 'DM Sans'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tap a row to highlight. Duration = Total Content / Flow Rate',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF5F5E5A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    const headerStyle = TextStyle(
      fontFamily: 'DM Sans',
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Color(0xFF1A1A2E),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Expanded(child: Text('Flow Rate (L/min)', style: headerStyle)),
          Expanded(child: Text('Duration (min)', style: headerStyle, textAlign: TextAlign.center)),
          Expanded(child: Text('Duration (hr)', style: headerStyle, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _ConsumptionRowData {
  final int flowRate;
  final double durationMin;
  final double durationHr;

  const _ConsumptionRowData({
    required this.flowRate,
    required this.durationMin,
    required this.durationHr,
  });
}
