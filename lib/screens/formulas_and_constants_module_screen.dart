import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_header.dart';
import 'profile_screen.dart';

/// Screen B: Formulas and Constants Module
/// Display anesthesia formulas and reference constants
class FormulasAndConstantsModuleScreen extends StatelessWidget {
  const FormulasAndConstantsModuleScreen({super.key});

  /// Copy formula to clipboard with feedback
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Formula copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF4A90E2),
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
              title: 'Formulas and Constants',
              breadcrumb: 'Home • Formulas and Constants',
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
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF5F7FA),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Volatile Formulas Section Header
                    _buildSectionHeader('Volatile Anesthetic Formulas'),
                    const SizedBox(height: 16),

                    // 1. Biro's Formula
                    _buildFormulaCard(
                      index: '1',
                      title: 'Biro\'s Formula',
                      formula: 'Consumption (ml) = (FGF × C × T × MW) / (2412 × 100)',
                      variables: [
                        'FGF = Fresh Gas Flow (L/min)',
                        'C = Concentration (%)',
                        'T = Time (minutes)',
                        'MW = Molecular Weight (g/mol)',
                        '2412 = Constant (molar volume at STP)',
                      ],
                      explanation:
                          'Standard formula for calculating volatile anesthetic consumption based on gas flow, concentration, and time.',
                    ),
                    const SizedBox(height: 16),

                    // 2. Dion's Formula
                    _buildFormulaCard(
                      index: '2',
                      title: 'Dion\'s Formula',
                      formula: 'Consumption (ml/hr) = (FGF × C × LVC) / 100',
                      variables: [
                        'FGF = Fresh Gas Flow (L/min)',
                        'C = Concentration (%)',
                        'LVC = Liquid to Vapor Constant',
                      ],
                      explanation:
                          'Simplified formula for hourly consumption calculation using the liquid-to-vapor constant.',
                    ),
                    const SizedBox(height: 16),

                    // 3. Weight-Based Formula
                    _buildFormulaCard(
                      index: '3',
                      title: 'Weight-Based Formula',
                      formula: 'Consumption (ml) = (Initial Weight - Final Weight) / Density',
                      variables: [
                        'Initial Weight = Weight before procedure (g)',
                        'Final Weight = Weight after procedure (g)',
                        'Density = Anesthetic agent density (g/ml)',
                      ],
                      explanation:
                          'Direct measurement method based on vaporizer bottle weight difference.',
                    ),
                    const SizedBox(height: 16),

                    // Volatile Agents Constants Table
                    _buildVolatileConstantsTable(),
                    const SizedBox(height: 20),

                    // Oxygen Cylinder Section Header
                    _buildSectionHeader('Oxygen Cylinder Formulas'),
                    const SizedBox(height: 16),

                    // 4. Oxygen Content Formula
                    _buildFormulaCard(
                      index: '4',
                      title: 'Oxygen Content Formula',
                      formula: 'Total Content (L) = Cylinder Pressure (Bar) × Cylinder Factor',
                      variables: [
                        'Cylinder Pressure = Current pressure reading (Bar/PSI)',
                        'Cylinder Factor = Agent-specific conversion factor',
                      ],
                      explanation:
                          'Calculates total available oxygen content in the cylinder.',
                    ),
                    const SizedBox(height: 16),

                    // 5. Oxygen Duration Formula
                    _buildFormulaCard(
                      index: '5',
                      title: 'Oxygen Duration Formula',
                      formula: 'Duration (min) = Total Content (L) / Flow Rate (L/min)',
                      variables: [
                        'Total Content = Available oxygen (L)',
                        'Flow Rate = Oxygen flow rate (L/min)',
                      ],
                      explanation: 'Determines how long the cylinder will last at a given flow rate.',
                    ),
                    const SizedBox(height: 16),

                    // Cylinder Factors Table
                    _buildCylinderFactorsTable(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build section header with gradient background
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFFB0C4DE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: 16,
            fontFamily: 'DM Sans',
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  /// Build formula card with title, formula, variables, and explanation
  Widget _buildFormulaCard({
    required String index,
    required String title,
    required String formula,
    required List<String> variables,
    required String explanation,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title without copy button
              Text(
                '$index. $title',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                  fontFamily: 'DM Sans',
                ),
              ),
              const SizedBox(height: 12),

              // Formula Box with Copy Button (Absolute Positioned)
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                    ),
                    child: Text(
                      formula,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                        fontFamily: 'Courier New',
                        letterSpacing: 0.3,
                        height: 1.4,
                      ),
                    ),
                  ),
                  // Copy Button - Gray, Top Right Corner
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _copyToClipboard(context, formula),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B7280),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.content_copy,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Variables Section
              const Text(
                'Where:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                  fontFamily: 'DM Sans',
                ),
              ),
              const SizedBox(height: 8),
              ...variables.map(
                (variable) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• $variable',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF374151),
                      fontFamily: 'DM Sans',
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Explanation
              Text(
                explanation,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4B5563),
                  fontFamily: 'DM Sans',
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build Volatile Agents Constants Table
  Widget _buildVolatileConstantsTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Volatile Agents Constants',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
              fontFamily: 'DM Sans',
            ),
          ),
          const SizedBox(height: 12),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Agent',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'MW (g/mol)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                      fontFamily: 'DM Sans',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Density',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                      fontFamily: 'DM Sans',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'LVC',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                      fontFamily: 'DM Sans',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Table Rows
          _buildTableRow('Isoflurane', '184.5', '1.496', '195'),
          _buildTableRow('Sevoflurane', '200.1', '1.52', '183'),
          _buildTableRow('Desflurane', '168', '1.465', '210'),
          _buildTableRow('Halothane', '197.4', '1.86', '227'),

          const SizedBox(height: 12),
          const Text(
            'MW = Molecular Weight | LVC = Liquid to Vapor Constant',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF4B5563),
              fontFamily: 'DM Sans',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build table row
  Widget _buildTableRow(String agent, String mw, String density, String lvc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              agent,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF111827),
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              mw,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              density,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              lvc,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Build Cylinder Factors Table
  Widget _buildCylinderFactorsTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Oxygen Cylinder Factors',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
              fontFamily: 'DM Sans',
            ),
          ),
          const SizedBox(height: 16),

          // Cylinder Factor Formula Box with Builder for context
          Builder(
            builder: (context) => _buildCylinderFormulaBoxWithContext(context),
          ),
          const SizedBox(height: 16),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Cylinder',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Factor',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                      fontFamily: 'DM Sans',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Typical Use',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                      fontFamily: 'DM Sans',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Table Rows
          _buildCylinderRow('A Cylinder', '0.625', 'Portable'),
          _buildCylinderRow('B Cylinder', '0.625', 'Portable'),
          _buildCylinderRow('C Cylinder', '0.625', 'Portable'),
          _buildCylinderRow('D Cylinder', '0.16', 'Small portable'),
          _buildCylinderRow('E Cylinder', '3.0', 'Portable'),
          _buildCylinderRow('F Cylinder', '1.68', 'Large portable'),
          _buildCylinderRow('G Cylinder', '2.41', 'Large stationary'),
          _buildCylinderRow('H Cylinder', '3.14', 'Hospital supply'),

          const SizedBox(height: 12),
          const Text(
            'Cylinder Factor = Constant × Molecular Weight | Use for calculating available oxygen from pressure readings',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF4B5563),
              fontFamily: 'DM Sans',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build cylinder formula box with copy button (Gray, Top Right)
  Widget _buildCylinderFormulaBoxWithContext(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: Text(
            'Available O2 (L) = Pressure (Bar) × Cylinder Factor',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
              fontFamily: 'Courier New',
              letterSpacing: 0.3,
              height: 1.4,
            ),
          ),
        ),
        // Copy Button - Gray, Top Right Corner
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _copyToClipboard(
              context,
              'Available O2 (L) = Pressure (Bar) × Cylinder Factor',
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6B7280),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.content_copy,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build cylinder table row
  Widget _buildCylinderRow(String cylinder, String factor, String use) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              cylinder,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF111827),
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              factor,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              use,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
