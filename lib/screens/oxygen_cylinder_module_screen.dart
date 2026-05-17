import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/app_header.dart';
import '../widgets/custom_button.dart' show PrimaryButton;
import '../widgets/pressure_input_field.dart';
import 'oxygen_result_screen.dart';
import 'settings_screen.dart';

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

  @override
  void dispose() {
    _pressureController.dispose();
    super.dispose();
  }

  double get _selectedFactor => _cylinderFactors[_selectedCylinderType] ?? 0.0;

  void _calculateTotalContent() {
    final text = _pressureController.text.trim();
    
    // Manual validation
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pressure is required')),
      );
      return;
    }

    final pressure = double.tryParse(text);
    if (pressure == null || pressure <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid pressure greater than 0')),
      );
      return;
    }

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

    Navigator.push(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (context, animation, secondaryAnimation) => OxygenResultScreen(
          cylinderType: _selectedCylinderType ?? 'A Cylinder',
          pressure: pressure,
          factor: factor,
          totalContent: totalContent,
        ),
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
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
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
          PressureInputField(
            initialValue: _pressureController.text,
            onPressureChanged: (value) {
              setState(() {
                _pressureController.text = value;
              });
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
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF185FA5)),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
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
