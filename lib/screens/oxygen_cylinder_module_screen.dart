import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import 'profile_screen.dart';
import '../widgets/macmind_design.dart';
import '../widgets/custom_button.dart' show PrimaryButton;

/// Screen B: Oxygen Cylinder Module
/// Calculate cylinder duration based on cylinder type, pressure, and factor
class OxygenCylinderModuleScreen extends StatefulWidget {
  const OxygenCylinderModuleScreen({super.key});

  @override
  State<OxygenCylinderModuleScreen> createState() =>
      _OxygenCylinderModuleScreenState();
}

class _OxygenCylinderModuleScreenState extends State<OxygenCylinderModuleScreen> {
  late TextEditingController _cylinderTypeController;
  late TextEditingController _pressureController;
  late TextEditingController _cylinderFactorController;
  late TextEditingController _flowRateController;

  String _selectedCylinderType = 'D Cylinder';
  double? _calculatedDuration;
  bool _showResult = false;

  final Map<String, double> _cylinderFactors = {
    'A Cylinder': 0.16,
    'B Cylinder': 0.30,
    'C Cylinder': 0.52,
    'D Cylinder': 0.68,
    'E Cylinder': 0.28,
    'F Cylinder': 1.86,
    'G Cylinder': 2.41,
    'H Cylinder': 3.14,
    'K Cylinder': 3.14,
    'M Cylinder': 1.56,
  };

  @override
  void initState() {
    super.initState();
    _cylinderTypeController = TextEditingController(text: _selectedCylinderType);
    _pressureController = TextEditingController();
    _cylinderFactorController = TextEditingController(
      text: _cylinderFactors[_selectedCylinderType]?.toString() ?? '0.68',
    );
    _flowRateController = TextEditingController();
  }

  @override
  void dispose() {
    _cylinderTypeController.dispose();
    _pressureController.dispose();
    _cylinderFactorController.dispose();
    _flowRateController.dispose();
    super.dispose();
  }

  void _onCylinderTypeChanged(String? newType) {
    if (newType == null) return;
    setState(() {
      _selectedCylinderType = newType;
      _cylinderTypeController.text = newType;
      final factor = _cylinderFactors[newType] ?? 0.68;
      _cylinderFactorController.text = factor.toString();
    });
  }

  void _calculateDuration() {
    final pressure = double.tryParse(_pressureController.text);
    final factor = double.tryParse(_cylinderFactorController.text);
    final flowRate = double.tryParse(_flowRateController.text);

    if (pressure == null || factor == null || flowRate == null || flowRate == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid values')),
      );
      return;
    }

    // Duration in minutes = (Pressure × Factor) / Flow Rate
    final duration = (pressure * factor) / flowRate;

    setState(() {
      _calculatedDuration = duration;
      _showResult = true;
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
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF5F7FA),
              padding: const EdgeInsets.all(16),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const MacMindInfoCard(
                    icon: Icons.info_outline,
                    child: Text(
                      'Estimate how long your oxygen cylinder will last using the current pressure and flow rate',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        height: 1.5,
                        color: MacMindColors.gray600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const MacMindSectionLabel(text: 'Cylinder settings'),
                  const SizedBox(height: 12),
                  _buildDropdownField(context),
                  const SizedBox(height: 12),
                  _buildField(
                    context,
                    label: 'Pressure (PSI)',
                    controller: _pressureController,
                    hint: 'Enter cylinder pressure',
                    icon: Icons.speed,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    context,
                    label: 'Cylinder Factor',
                    controller: _cylinderFactorController,
                    hint: 'Auto-calculated',
                    icon: Icons.info_outline,
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    context,
                    label: 'Flow Rate (L/min)',
                    controller: _flowRateController,
                    hint: 'Enter desired flow rate',
                    icon: Icons.air,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Calculate Duration',
                      onPressed: _calculateDuration,
                      icon: Icons.calculate,
                    ),
                  ),
                  if (_showResult) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MacMindColors.teal50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x331D9E75)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: MacMindColors.teal400, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Duration Calculated',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: MacMindColors.teal600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: MacMindColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: MacMindColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Duration',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: MacMindColors.gray600,
                                  ),
                                ),
                                Text(
                                  '${_calculatedDuration?.toStringAsFixed(1)} minutes',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: MacMindColors.teal400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Approximate duration based on current settings',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: MacMindColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: MacMindColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MacMindColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCylinderType,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: MacMindColors.gray400),
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            color: MacMindColors.textDark,
          ),
          items: _cylinderFactors.keys.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: _onCylinderTypeChanged,
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: MacMindColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            color: MacMindColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              color: MacMindColors.gray400,
            ),
            prefixIcon: Icon(icon, size: 18, color: MacMindColors.blue600),
            filled: true,
            fillColor: MacMindColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: MacMindColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: MacMindColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: MacMindColors.blue600, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: MacMindColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
