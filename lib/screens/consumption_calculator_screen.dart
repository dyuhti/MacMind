import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';
import 'results_screen.dart';
import '../widgets/app_header.dart';
import 'case_history_screen.dart';
import 'profile_screen.dart';
// case_history_dialog and macmind_design imports removed (unused)

/// Consumption Calculator Screen
class ConsumptionCalculatorScreen extends StatefulWidget {
  final String patientName;
  final String idNumber;
  final DateTime date;
  final String surgeryType;
  final String agent;
  final double lvConstant;
  final double liquidVaporConstant;
  final double density;

  const ConsumptionCalculatorScreen({
    super.key,
    required this.patientName,
    required this.idNumber,
    required this.date,
    required this.surgeryType,
    required this.agent,
    required this.lvConstant,
    required this.liquidVaporConstant,
    required this.density,
  });

  @override
  State<ConsumptionCalculatorScreen> createState() => _ConsumptionCalculatorScreenState();
}

class _ConsumptionCalculatorScreenState extends State<ConsumptionCalculatorScreen> {
  // Induction Phase Controllers
  late TextEditingController _inductionFGFController;
  late TextEditingController _inductionConcController;
  late TextEditingController _inductionTimeController;

  // Maintenance Phase - List of rows
  List<_MaintenanceRow> _maintenanceRows = [];

  // Weight-Based Method Controllers
  late TextEditingController _initialWeightController;
  late TextEditingController _finalWeightController;

  // Error state tracking - Induction
  bool _inductionFGFError = false;
  bool _inductionConcError = false;
  bool _inductionTimeError = false;

  // Error state tracking - Weight-Based
  bool _initialWeightError = false;
  bool _finalWeightError = false;

  static const Map<String, Map<String, double>> _agentConstantMap = {
    'Isoflurane': {
      'molecularMass': 184.49,
      'liquidToVaporConstant': 195,
      'density': 1.50,
    },
    'Sevoflurane': {
      'molecularMass': 200.05,
      'liquidToVaporConstant': 184,
      'density': 1.52,
    },
    'Desflurane': {
      'molecularMass': 168.04,
      'liquidToVaporConstant': 210,
      'density': 1.46,
    },
    'Halothane': {
      'molecularMass': 197.38,
      'liquidToVaporConstant': 229,
      'density': 1.86,
    },
  };

  @override
  void initState() {
    super.initState();
    // Induction Phase
    _inductionFGFController = TextEditingController();
    _inductionConcController = TextEditingController();
    _inductionTimeController = TextEditingController();

    // Weight-Based Method
    _initialWeightController = TextEditingController();
    _finalWeightController = TextEditingController();

    // Initialize maintenance rows with 4 empty rows
    _maintenanceRows = List.generate(
      4,
      (index) => _MaintenanceRow(
        fgfController: TextEditingController(),
        concController: TextEditingController(),
        timeController: TextEditingController(),
      ),
    );
  }

  @override
  void dispose() {
    // Induction Phase
    _inductionFGFController.dispose();
    _inductionConcController.dispose();
    _inductionTimeController.dispose();

    // Maintenance Phase
    for (var row in _maintenanceRows) {
      row.dispose();
    }

    // Weight-Based Method
    _initialWeightController.dispose();
    _finalWeightController.dispose();
    super.dispose();
  }

  void _calculateConsumption() {
    final results = calculateResults();
    if (results == null) {
      return;
    }

    // Get molecular mass and liquid-to-vapor constant from agent constants
    final constants = _agentConstantMap[widget.agent] ?? {
      'molecularMass': widget.lvConstant,
      'liquidToVaporConstant': widget.liquidVaporConstant,
      'density': widget.density,
    };

    final molecularMass = constants['molecularMass'] ?? widget.lvConstant;
    final liquidToVaporConstant =
        constants['liquidToVaporConstant'] ?? widget.liquidVaporConstant;

    // Prepare induction data
    final inductionFGF = double.tryParse(_inductionFGFController.text.trim());
    final inductionConc = double.tryParse(_inductionConcController.text.trim());
    final inductionTime = double.tryParse(_inductionTimeController.text.trim());

    // Prepare maintenance rows data (only completed rows)
    final maintenanceRows = <Map<String, double>>[];
    for (int i = 0; i < _maintenanceRows.length; i++) {
      final row = _maintenanceRows[i];
      final fgf = double.tryParse(row.fgfController.text.trim());
      final conc = double.tryParse(row.concController.text.trim());
      final time = double.tryParse(row.timeController.text.trim());

      // Include only completed rows
      if (fgf != null && conc != null && time != null && fgf > 0 && conc > 0 && time > 0) {
        maintenanceRows.add({
          'rowNumber': (i + 1).toDouble(),
          'fgf': fgf,
          'conc': conc,
          'time': time,
        });
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          selectedAgent: widget.agent,
          biroResult: results.biroResult,
          dionResult: results.dionResult,
          inductionBiro: results.inductionBiro,
          inductionDion: results.inductionDion,
          maintenanceCalculations: results.maintenanceCalculations,
          weightBasedResult: results.weightBasedResult,
          patientName: widget.patientName,
          idNumber: widget.idNumber,
          date: widget.date,
          surgeryType: widget.surgeryType,
          molecularMass: molecularMass,
          liquidToVaporConstant: liquidToVaporConstant,
          freshGasFlow: results.freshGasFlow,
          dialConcentration: results.dialConcentration,
          timeMinutes: results.timeMinutes,
          density: results.density,
          initialWeight: results.initialWeight,
          finalWeight: results.finalWeight,
          inductionFGF: inductionFGF ?? 0,
          inductionConcentration: inductionConc ?? 0,
          inductionTime: inductionTime ?? 0,
          maintenanceRows: maintenanceRows,
        ),
      ),
    );
  }

  _CalculationResults? calculateResults() {
    if (!_validateForm()) {
      return null;
    }

    final constants = _agentConstantMap[widget.agent] ?? {
      'molecularMass': widget.lvConstant,
      'liquidToVaporConstant': widget.liquidVaporConstant,
      'density': widget.density,
    };

    final molecularMass = constants['molecularMass'] ?? widget.lvConstant;
    final liquidToVaporConstant =
        constants['liquidToVaporConstant'] ?? widget.liquidVaporConstant;
    final density = constants['density'] ?? widget.density;

    // Get weight values
    final initialWeight = double.tryParse(_initialWeightController.text.trim());
    final finalWeight = double.tryParse(_finalWeightController.text.trim());

    if (initialWeight == null || finalWeight == null) {
      _showErrorSnackBar('Please enter valid numeric values in all fields');
      return null;
    }

    // Calculate consumption row-wise (induction + each completed maintenance row)
    double totalBiroResult = 0;
    double totalDionResult = 0;
    double inductionBiro = 0;
    double inductionDion = 0;
    final maintenanceCalculations = <Map<String, double>>[];
    double totalTimeMinutes = 0;
    double totalFreshGasFlow = 0;
    double totalDialConcentration = 0;
    int rowCount = 0;

    // Process Induction Phase
    final inductionFGF = double.tryParse(_inductionFGFController.text.trim());
    final inductionConc = double.tryParse(_inductionConcController.text.trim());
    final inductionTime = double.tryParse(_inductionTimeController.text.trim());

    if (inductionFGF != null && inductionConc != null && inductionTime != null) {
      // Biro row-wise: (FGF × Concentration × Time) / vaporLiquidConstant × 10
      final biroForRow =
          ((inductionFGF * inductionConc * inductionTime) / liquidToVaporConstant) * 10;
      final concentrationFraction = inductionConc / 100;
      final dionForRow =
          (((concentrationFraction * inductionFGF * inductionTime * molecularMass) /
                  (241.2 * density))) *
              10;

      inductionBiro = biroForRow;
      inductionDion = dionForRow;
      totalBiroResult += biroForRow;
      totalDionResult += dionForRow;
      totalTimeMinutes += inductionTime;
      totalFreshGasFlow += inductionFGF;
      totalDialConcentration += inductionConc;
      rowCount++;
    }

    // Process Maintenance Rows
    for (int i = 0; i < _maintenanceRows.length; i++) {
      final row = _maintenanceRows[i];
      final fgf = double.tryParse(row.fgfController.text.trim());
      final conc = double.tryParse(row.concController.text.trim());
      final time = double.tryParse(row.timeController.text.trim());

      if (fgf != null && conc != null && time != null) {
        if (fgf > 0 && conc > 0 && time > 0) {
          final rowNumber = (i + 1).toDouble();
          final biroForRow = ((fgf * conc * time) / liquidToVaporConstant) * 10;
          final concentrationFraction = conc / 100;
          final dionForRow = (((concentrationFraction * fgf * time * molecularMass) /
                  (241.2 * density))) *
              10;

          maintenanceCalculations.add({
            'row': rowNumber,
            'biro': biroForRow,
            'dion': dionForRow,
          });

          totalBiroResult += biroForRow;
          totalDionResult += dionForRow;
          totalTimeMinutes += time;
          totalFreshGasFlow += fgf;
          totalDialConcentration += conc;
          rowCount++;
        }
      }
    }

    if (rowCount == 0) {
      _showErrorSnackBar('Please fill at least Induction or one Maintenance row');
      return null;
    }

    // Calculate average FGF and Concentration for display
    final avgFreshGasFlow = rowCount > 0 ? (totalFreshGasFlow / rowCount).toDouble() : 0.0;
    final avgDialConcentration = rowCount > 0 ? (totalDialConcentration / rowCount).toDouble() : 0.0;

    final weightBasedConsumed = (initialWeight - finalWeight) / density;

    return _CalculationResults(
      biroResult: _roundToOneDecimal(totalBiroResult),
      dionResult: _roundToOneDecimal(totalDionResult),
      inductionBiro: _roundToOneDecimal(inductionBiro),
      inductionDion: _roundToOneDecimal(inductionDion),
      maintenanceCalculations: maintenanceCalculations
          .map((e) => <String, double>{
                'row': e['row'] ?? 0.0,
                'biro': _roundToOneDecimal(e['biro'] ?? 0.0),
                'dion': _roundToOneDecimal(e['dion'] ?? 0.0),
              })
          .toList(),
      weightBasedResult: _roundToTwoDecimal(weightBasedConsumed),
      freshGasFlow: avgFreshGasFlow,
      dialConcentration: avgDialConcentration,
      timeMinutes: totalTimeMinutes,
      density: density,
      initialWeight: initialWeight,
      finalWeight: finalWeight,
    );
  }

  double _roundToOneDecimal(double value) {
    return double.parse(value.toStringAsFixed(1));
  }

  double _roundToTwoDecimal(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  bool _validateForm() {
    // ===== INDUCTION PHASE VALIDATION =====
    // Induction is NOW OPTIONAL but must use ALL-OR-NONE validation
    final inductionFGF = _inductionFGFController.text.trim();
    final inductionConc = _inductionConcController.text.trim();
    final inductionTime = _inductionTimeController.text.trim();

    final inductionFGFEmpty = inductionFGF.isEmpty;
    final inductionConcEmpty = inductionConc.isEmpty;
    final inductionTimeEmpty = inductionTime.isEmpty;

    // Check if induction is partially filled (some but not all fields)
    final inductionFilledCount = [!inductionFGFEmpty, !inductionConcEmpty, !inductionTimeEmpty]
        .where((v) => v)
        .length;

    setState(() {
      _inductionFGFError = false;
      _inductionConcError = false;
      _inductionTimeError = false;
    });

    if (inductionFilledCount > 0 && inductionFilledCount < 3) {
      // Partial induction row detected - ALL-OR-NONE violation
      _showErrorSnackBar('Please complete all 3 fields in Induction');
      setState(() {
        _inductionFGFError = inductionFGFEmpty;
        _inductionConcError = inductionConcEmpty;
        _inductionTimeError = inductionTimeEmpty;
      });
      return false;
    }

    // If induction is fully filled, validate values are positive
    bool hasInductionData = false;
    if (!inductionFGFEmpty && !inductionConcEmpty && !inductionTimeEmpty) {
      final inductionFGFVal = double.tryParse(inductionFGF);
      final inductionConcVal = double.tryParse(inductionConc);
      final inductionTimeVal = double.tryParse(inductionTime);

      if (inductionFGFVal == null || inductionFGFVal <= 0 ||
          inductionConcVal == null || inductionConcVal <= 0 ||
          inductionTimeVal == null || inductionTimeVal <= 0) {
        _showErrorSnackBar('Induction values must be positive numbers.');
        setState(() {
          _inductionFGFError = inductionFGFVal == null || inductionFGFVal <= 0;
          _inductionConcError = inductionConcVal == null || inductionConcVal <= 0;
          _inductionTimeError = inductionTimeVal == null || inductionTimeVal <= 0;
        });
        return false;
      }
      hasInductionData = true;
    }

    // ===== MAINTENANCE ROWS VALIDATION =====
    // Each maintenance row must use ALL-OR-NONE validation
    bool hasMaintenanceData = false;
    for (int i = 0; i < _maintenanceRows.length; i++) {
      final row = _maintenanceRows[i];
      final fgf = row.fgfController.text.trim();
      final conc = row.concController.text.trim();
      final time = row.timeController.text.trim();

      final fgfEmpty = fgf.isEmpty;
      final concEmpty = conc.isEmpty;
      final timeEmpty = time.isEmpty;

      // Check if this is a partial row (some but not all fields are filled)
      final filledCount = [!fgfEmpty, !concEmpty, !timeEmpty].where((v) => v).length;
      if (filledCount > 0 && filledCount < 3) {
        // Partial row detected - ALL-OR-NONE violation
        _showErrorSnackBar('Please complete all 3 fields in Maintenance Row ${i + 1}');
        return false;
      }

      // If row has complete data, validate values are positive
      if (!fgfEmpty && !concEmpty && !timeEmpty) {
        final fgfVal = double.tryParse(fgf);
        final concVal = double.tryParse(conc);
        final timeVal = double.tryParse(time);

        if (fgfVal == null || fgfVal <= 0 ||
            concVal == null || concVal <= 0 ||
            timeVal == null || timeVal <= 0) {
          _showErrorSnackBar('Maintenance Row ${i + 1} values must be positive numbers.');
          return false;
        }
        hasMaintenanceData = true;
      }
    }

    // ===== CHECK AT LEAST ONE ROW IS FILLED =====
    // Either induction or at least one maintenance row must be filled
    if (!hasInductionData && !hasMaintenanceData) {
      _showErrorSnackBar('Please fill at least Induction or one Maintenance row');
      return false;
    }

    // ===== WEIGHT-BASED METHOD VALIDATION =====
    final initialWeight = _initialWeightController.text.trim();
    final finalWeight = _finalWeightController.text.trim();

    if (initialWeight.isEmpty || finalWeight.isEmpty) {
      _showErrorSnackBar('Please fill weight fields.');
      setState(() {
        _initialWeightError = initialWeight.isEmpty;
        _finalWeightError = finalWeight.isEmpty;
      });
      return false;
    }

    final initialWeightVal = double.tryParse(initialWeight);
    final finalWeightVal = double.tryParse(finalWeight);

    if (initialWeightVal == null || initialWeightVal <= 0 ||
        finalWeightVal == null || finalWeightVal <= 0) {
      _showErrorSnackBar('Weight values must be positive numbers.');
      setState(() {
        _initialWeightError = initialWeightVal == null || initialWeightVal <= 0;
        _finalWeightError = finalWeightVal == null || finalWeightVal <= 0;
      });
      return false;
    }

    if (finalWeightVal > initialWeightVal) {
      setState(() {
        _initialWeightError = true;
        _finalWeightError = true;
      });
      _showErrorSnackBar('Final weight cannot be greater than initial weight.');
      return false;
    }

    return true;
  }

  void _resetForm() {
    _inductionFGFController.clear();
    _inductionConcController.clear();
    _inductionTimeController.clear();

    for (var row in _maintenanceRows) {
      row.fgfController.clear();
      row.concController.clear();
      row.timeController.clear();
    }

    _initialWeightController.clear();
    _finalWeightController.clear();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
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
              title: 'Consumption Calculator',
              breadcrumb: 'Home • New Case • Calculator',
              showBack: true,
              onBack: () => Navigator.pop(context),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppHeaderActionButton(
                    icon: Icons.history,
                    tooltip: 'View History',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CaseHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  AppHeaderProfileAvatar(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF000000).withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Formula Inputs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildPhaseSection(
                            title: 'Induction',
                            fgfController: _inductionFGFController,
                            concController: _inductionConcController,
                            timeController: _inductionTimeController,
                            fgfError: _inductionFGFError,
                            concError: _inductionConcError,
                            timeError: _inductionTimeError,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Maintenance',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _maintenanceRows.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildMaintenanceRow(
                                row: _maintenanceRows[index],
                                rowIndex: index,
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _maintenanceRows.add(
                                    _MaintenanceRow(
                                      fgfController: TextEditingController(),
                                      concController: TextEditingController(),
                                      timeController: TextEditingController(),
                                    ),
                                  );
                                });
                              },
                              icon: const Icon(Icons.add, size: 22, color: Colors.white),
                              label: const Text(
                                'Add Row',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: AppColors.primary.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDCE6F2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Weight-Based Method',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            label: 'Initial Weight (kg)',
                            hint: 'Enter initial weight',
                            controller: _initialWeightController,
                            keyboardType: TextInputType.number,
                            isError: _initialWeightError,
                            errorMessage: _initialWeightError ? 'Initial weight must be greater than 0' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            label: 'Final Weight (kg)',
                            hint: 'Enter final weight',
                            controller: _finalWeightController,
                            keyboardType: TextInputType.number,
                            isError: _finalWeightError,
                            errorMessage: _finalWeightError ? 'Final weight must be greater than 0' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _calculateConsumption,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Calculate',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _resetForm,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseSection({
    required String title,
    required TextEditingController fgfController,
    required TextEditingController concController,
    required TextEditingController timeController,
    required bool fgfError,
    required bool concError,
    required bool timeError,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 12),
        // Single row with 3 compact input boxes
        Row(
          children: [
            Expanded(
              child: _buildCompactInputField(
                label: 'FGF (L)',
                hint: '0.0',
                controller: fgfController,
                isError: fgfError,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactInputField(
                label: 'Conc (%)',
                hint: '0.0',
                controller: concController,
                isError: concError,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactInputField(
                label: 'Time (min)',
                hint: '0',
                controller: timeController,
                isError: timeError,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMaintenanceRow({
    required _MaintenanceRow row,
    required int rowIndex,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Row Number/Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryLight, width: 1),
            ),
            child: Center(
              child: Text(
                '${rowIndex + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Three input fields
          Expanded(
            child: _buildCompactInputField(
              label: 'FGF',
              hint: '0.0',
              controller: row.fgfController,
              isError: false,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildCompactInputField(
              label: 'Conc',
              hint: '0.0',
              controller: row.concController,
              isError: false,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildCompactInputField(
              label: 'Time',
              hint: '0',
              controller: row.timeController,
              isError: false,
            ),
          ),
          const SizedBox(width: 10),
          // Delete button
          GestureDetector(
            onTap: () {
              setState(() {
                row.dispose();
                _maintenanceRows.removeAt(rowIndex);
              });
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isError,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 38,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFD1D5DB),
                fontSize: 12,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isError ? const Color(0xFFDC2626) : const Color(0xFFE5E7EB),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isError ? const Color(0xFFDC2626) : const Color(0xFFE5E7EB),
                  width: isError ? 1.5 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isError ? const Color(0xFFDC2626) : AppColors.primary,
                  width: 1.5,
                ),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool? isError,
    String? errorMessage,
  }) {
    final hasError = isError ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFB5BFC7),
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError ? const Color(0xFFDC2626) : const Color(0xFFDCE6F2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError ? const Color(0xFFDC2626) : const Color(0xFFDCE6F2),
                  width: hasError ? 2 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError ? const Color(0xFFDC2626) : AppColors.primary,
                  width: 2,
                ),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
        ),
        if (hasError && errorMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            errorMessage,
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ],
    );
  }
}

class _MaintenanceRow {
  final TextEditingController fgfController;
  final TextEditingController concController;
  final TextEditingController timeController;

  _MaintenanceRow({
    required this.fgfController,
    required this.concController,
    required this.timeController,
  });

  void dispose() {
    fgfController.dispose();
    concController.dispose();
    timeController.dispose();
  }
}

class _CalculationResults {
  final double biroResult;
  final double dionResult;
  final double inductionBiro;
  final double inductionDion;
  final List<Map<String, double>> maintenanceCalculations;
  final double weightBasedResult;
  final double freshGasFlow;
  final double dialConcentration;
  final double timeMinutes;
  final double density;
  final double initialWeight;
  final double finalWeight;

  const _CalculationResults({
    required this.biroResult,
    required this.dionResult,
    required this.inductionBiro,
    required this.inductionDion,
    required this.maintenanceCalculations,
    required this.weightBasedResult,
    required this.freshGasFlow,
    required this.dialConcentration,
    required this.timeMinutes,
    required this.density,
    required this.initialWeight,
    required this.finalWeight,
  });
}
