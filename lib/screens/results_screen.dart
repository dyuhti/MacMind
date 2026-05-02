import 'package:flutter/material.dart';
import '../config/app_colors.dart';
// api_config and http imports removed (unused)
import '../models/case_history_item.dart';
import '../services/auth_service.dart';
import '../services/export_service.dart';
import '../services/session_history.dart';
import '../services/case_service.dart';
import '../widgets/app_header.dart';
import 'profile_screen.dart';
import '../widgets/case_history_dialog.dart';
// macmind_design removed (unused)

class ResultsScreen extends StatefulWidget {
  final double biroResult;
  final double dionResult;
  final double inductionBiro;
  final double inductionDion;
  final List<Map<String, double>> maintenanceCalculations;
  final double weightBasedResult;
  final String patientName;
  final String idNumber;
  final DateTime date;
  final String surgeryType;
  final String selectedAgent;
  final double molecularMass;
  final double liquidToVaporConstant;
  final double freshGasFlow;
  final double dialConcentration;
  final double timeMinutes;
  final double density;
  final double? initialWeight;
  final double? finalWeight;
  final double inductionFGF;
  final double inductionConcentration;
  final double inductionTime;
  final List<Map<String, double>> maintenanceRows;

  const ResultsScreen({
    super.key,
    required this.biroResult,
    required this.dionResult,
    this.inductionBiro = 0,
    this.inductionDion = 0,
    this.maintenanceCalculations = const [],
    required this.weightBasedResult,
    required this.patientName,
    required this.idNumber,
    required this.date,
    required this.surgeryType,
    required this.selectedAgent,
    required this.molecularMass,
    required this.liquidToVaporConstant,
    required this.freshGasFlow,
    required this.dialConcentration,
    required this.timeMinutes,
    required this.density,
    this.initialWeight,
    this.finalWeight,
    this.inductionFGF = 0,
    this.inductionConcentration = 0,
    this.inductionTime = 0,
    this.maintenanceRows = const [],
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSaved = false;
  DateTime? _savedAt;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatMl(double value) {
    if (value.isNaN || value.isInfinite) {
      return '0.0';
    }
    return value.toStringAsFixed(1);
  }

  CaseHistoryItem _buildCaseHistoryItem({DateTime? savedAtOverride}) {
    return CaseHistoryItem(
      patientName: widget.patientName,
      idNumber: widget.idNumber,
      date: widget.date,
      surgeryType: widget.surgeryType,
      agent: widget.selectedAgent,
      freshGasFlow: widget.freshGasFlow,
      dialConcentration: widget.dialConcentration,
      timeMinutes: widget.timeMinutes,
      initialWeight: widget.initialWeight,
      finalWeight: widget.finalWeight,
      birosFormulaMl: widget.biroResult,
      dionsFormulaMl: widget.dionResult,
      weightBasedMl: widget.weightBasedResult,
      notes: _notesController.text.trim(),
      savedAt: savedAtOverride ?? DateTime.now(),
      inductionFGF: widget.inductionFGF,
      inductionConcentration: widget.inductionConcentration,
      inductionTime: widget.inductionTime,
      maintenanceRows: widget.maintenanceRows,
      inductionBiro: widget.inductionBiro,
      inductionDion: widget.inductionDion,
      maintenanceCalculations: widget.maintenanceCalculations,
      finalBiro: widget.biroResult,
      finalDion: widget.dionResult,
    );
  }

  Future<void> _saveCase() async {
    if (_isSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ This case is already saved'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    try {
      // Format date as YYYY-MM-DD
      final dateStr = '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}';
      
      print('💾 Attempting to save case...');
      print('👤 Patient: ${widget.patientName}');
      print('📅 Date: $dateStr');

      // Call the save case service
      final result = await CaseService.saveCase(
        patientName: widget.patientName,
        patientId: widget.idNumber,
        date: dateStr,
        surgeryType: widget.surgeryType,
        anestheticAgent: widget.selectedAgent,
        molecularMass: widget.molecularMass.toStringAsFixed(2),
        vaporConstant: widget.liquidToVaporConstant.toStringAsFixed(2),
        density: widget.density.toStringAsFixed(2),
        freshGasFlow: widget.freshGasFlow,
        dialConcentration: widget.dialConcentration,
        timeMinutes: widget.timeMinutes,
        initialWeight: widget.initialWeight,
        finalWeight: widget.finalWeight,
        biroFormula: widget.biroResult,
        dionFormula: widget.dionResult,
        weightBased: widget.weightBasedResult,
        notes: _notesController.text.trim(),
        inductionFGF: widget.inductionFGF,
        inductionConcentration: widget.inductionConcentration,
        inductionTime: widget.inductionTime,
        inductionBiro: widget.inductionBiro,
        inductionDion: widget.inductionDion,
        finalBiro: widget.biroResult,
        finalDion: widget.dionResult,
        maintenanceRows: widget.maintenanceRows
            .map((row) => row.map((key, value) => MapEntry(key, value as dynamic)))
            .toList(),
        maintenanceCalculations: widget.maintenanceCalculations
            .map((row) => row.map((key, value) => MapEntry(key, value as dynamic)))
            .toList(),
      );

      if (!mounted) return;

      if (result['success']) {
        // Also save to local session history
        final savedAt = DateTime.now();
        final item = _buildCaseHistoryItem(savedAtOverride: savedAt);
        SessionHistory.saveCase(item);

        setState(() {
          _isSaved = true;
          _savedAt = savedAt;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Case saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        print('✅ Case saved successfully');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['error'] ?? 'Failed to save case'}'),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 2),
          ),
        );
        print('❌ Failed to save case: ${result['error']}');
      }
    } catch (e) {
      if (!mounted) return;
      print('❌ Exception saving case: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _exportCurrentPdf() async {
    try {
      final userEmail = await AuthService.getLoggedInEmail();
      final item = _buildCaseHistoryItem(savedAtOverride: _savedAt ?? DateTime.now());
      final path = await ExportService.exportCaseAsPdf(item, userName: userEmail);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved to $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export PDF')),
      );
    }
  }

  Future<void> _exportCurrentExcel() async {
    try {
      final userEmail = await AuthService.getLoggedInEmail();
      final item = _buildCaseHistoryItem(savedAtOverride: _savedAt ?? DateTime.now());
      final path = await ExportService.exportCaseAsCsv(item, userName: userEmail);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel file saved to $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export Excel')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: false,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
            AppHeader(
              title: 'Results',
              breadcrumb: 'Home • New Case • Results',
              showBack: true,
              onBack: () => Navigator.pop(context),
              onProfileTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
            _ResultCard(
              title: "Biro's Formula",
              subtitle: 'Using vapor-liquid constant',
              value: _formatMl(widget.biroResult),
            ),
            const SizedBox(height: 14),
            _ResultCard(
              title: "Dion's Formula",
              subtitle: 'Using molar mass & density',
              value: _formatMl(widget.dionResult),
            ),
            const SizedBox(height: 14),
            _ResultCard(
              title: 'Weight-Based',
              subtitle: 'Direct weight measurement',
              value: _formatMl(widget.weightBasedResult),
            ),
            const SizedBox(height: 18),

            // NEW: Induction and Maintenance Details Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                  // Induction Section
                  const Text(
                    'Induction',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPhaseValueDisplay(
                        label: 'FGF',
                        value: widget.inductionFGF.toStringAsFixed(2),
                        unit: 'L',
                      ),
                      _buildPhaseValueDisplay(
                        label: 'Conc',
                        value: widget.inductionConcentration.toStringAsFixed(2),
                        unit: '%',
                      ),
                      _buildPhaseValueDisplay(
                        label: 'Time',
                        value: widget.inductionTime.toStringAsFixed(2),
                        unit: 'min',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPhaseValueDisplay(
                        label: 'Biro',
                        value: widget.inductionBiro.toStringAsFixed(1),
                        unit: 'mL',
                      ),
                      _buildPhaseValueDisplay(
                        label: 'Dion',
                        value: widget.inductionDion.toStringAsFixed(1),
                        unit: 'mL',
                      ),
                    ],
                  ),
                  
                  // Maintenance Section
                  if (widget.maintenanceRows.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 16),
                    const Text(
                      'Maintenance',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.maintenanceRows.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final row = widget.maintenanceRows[index];
                        final rowNum = row['rowNumber']?.toInt() ?? index + 1;
                        final fgf = row['fgf'] ?? 0.0;
                        final conc = row['concentration'] ?? 0.0;
                        final time = row['time'] ?? 0.0;

                        final calc = widget.maintenanceCalculations.firstWhere(
                          (e) => (e['row'] ?? -1).toInt() == rowNum,
                          orElse: () => const <String, double>{},
                        );
                        final rowBiro = calc['biro'] ?? 0.0;
                        final rowDion = calc['dion'] ?? 0.0;

                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFBFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Row Badge
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.primaryLight,
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$rowNum',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Values in row
                                  Expanded(
                                    child:
                                        _buildCompactMaintValue('FGF', fgf, 'L'),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildCompactMaintValue(
                                      'Conc',
                                      conc,
                                      '%',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildCompactMaintValue(
                                      'Time',
                                      time,
                                      'min',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Row $rowNum → Biro: ${rowBiro.toStringAsFixed(1)} mL | Dion: ${rowDion.toStringAsFixed(1)} mL',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF374151),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 12),
                  const Text(
                    'Final Totals',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPhaseValueDisplay(
                        label: 'Total Biro',
                        value: widget.biroResult.toStringAsFixed(1),
                        unit: 'mL',
                      ),
                      _buildPhaseValueDisplay(
                        label: 'Total Dion',
                        value: widget.dionResult.toStringAsFixed(1),
                        unit: 'mL',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 18),
            
            // Original Case Summary Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCE6F2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryRow('Selected Agent', widget.selectedAgent),
                  _summaryRow('Biro Formula', '${_formatMl(widget.biroResult)} mL'),
                  _summaryRow('Dion Formula', '${_formatMl(widget.dionResult)} mL'),
                  _summaryRow('Weight-Based', '${_formatMl(widget.weightBasedResult)} mL'),
                  const SizedBox(height: 8),
                  const Text(
                    'Case Summary',
                    style: TextStyle(
                      fontSize: 30 / 2,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _summaryRow('Patient Name', widget.patientName),
                  _summaryRow('ID Number', widget.idNumber),
                  _summaryRow('Date', _formatDate(widget.date)),
                  _summaryRow('Surgery Type', widget.surgeryType),
                  _summaryRow('Agent', widget.selectedAgent),
                  _summaryRow('Density', widget.density.toStringAsFixed(2)),
                  _summaryRow('Fresh Gas Flow', '${widget.freshGasFlow.toStringAsFixed(2)} L/min'),
                  _summaryRow('Dial Concentration', '${widget.dialConcentration.toStringAsFixed(2)} %'),
                  _summaryRow('Time', '${widget.timeMinutes.toStringAsFixed(2)} min'),
                  _summaryRow(
                    'Initial Weight',
                    widget.initialWeight != null
                        ? '${widget.initialWeight!.toStringAsFixed(2)} kg'
                        : '--',
                  ),
                  _summaryRow(
                    'Final Weight',
                    widget.finalWeight != null
                        ? '${widget.finalWeight!.toStringAsFixed(2)} kg'
                        : '--',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Notes (Optional)',
                    style: TextStyle(
                      fontSize: 16 / 2 * 1.75,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: 'Add any additional notes...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 14,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDCE6F2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDCE6F2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saveCase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.save_alt, color: Colors.white, size: 18),
                label: Text(
                  _isSaved ? 'Saved' : 'Save Case',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _outlineActionButton(
              label: 'Export PDF',
              icon: Icons.file_download_outlined,
              onPressed: _exportCurrentPdf,
            ),
            const SizedBox(height: 10),
            _outlineActionButton(
              label: 'Export Excel',
              icon: Icons.file_download_outlined,
              onPressed: _exportCurrentExcel,
            ),
            const SizedBox(height: 10),
            _outlineActionButton(
              label: 'View History',
              icon: Icons.history_outlined,
              onPressed: () => showCaseHistoryDialog(context),
            ),
            const SizedBox(height: 24),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEF2F7)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlineActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFDCE6F2), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
        ),
        icon: Icon(icon, size: 18, color: const Color(0xFF374151)),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseValueDisplay({
    required String label,
    required String value,
    required String unit,
  }) {
    return Column(
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFBFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactMaintValue(String label, double value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.toStringAsFixed(2),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            fontFamily: 'Inter',
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;

  const _ResultCard({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 30 / 2,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                  fontFamily: 'Inter',
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calculate_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 36 / 2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text(
                  'ml',
                  style: TextStyle(
                    fontSize: 22 / 2,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
