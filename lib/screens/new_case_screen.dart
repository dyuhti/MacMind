import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../widgets/app_header.dart';
import '../models/case_history_item.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';
import 'consumption_calculator_screen.dart';
import 'login_screen.dart';
import '../services/agent_constants_service.dart';
import 'case_history_screen.dart';
import '../providers/case_provider.dart';
// macmind_design import removed (not used here)

/// New Case Screen - Post-login form
class NewCaseScreen extends StatefulWidget {
  final CaseHistoryItem? caseData;

  const NewCaseScreen({super.key, this.caseData});

  @override
  State<NewCaseScreen> createState() => _NewCaseScreenState();
}

class _NewCaseScreenState extends State<NewCaseScreen> {
  late TextEditingController _patientNameController;
  late TextEditingController _idNumberController;
  late TextEditingController _surgeryTypeController;

  String _selectedAgent = 'Isoflurane';
  DateTime _selectedDate = DateTime.now();
  
  // Error state tracking
  bool _patientNameError = false;
  bool _idNumberError = false;
  bool _surgeryTypeError = false;

  final Map<String, Map<String, String>> _agentConstants = {
    'Isoflurane': {
      'molecularMass': '184.49',
      'liquidToVaporConstant': '195',
      'density': '1.50',
    },
    'Sevoflurane': {
      'molecularMass': '200.05',
      'liquidToVaporConstant': '184',
      'density': '1.52',
    },
    'Desflurane': {
      'molecularMass': '168.04',
      'liquidToVaporConstant': '210',
      'density': '1.46',
    },
    'Halothane': {
      'molecularMass': '197.38',
      'liquidToVaporConstant': '229',
      'density': '1.86',
    },
  };

  bool _isLoadingConstants = true;

  @override
  void initState() {
    super.initState();
    _patientNameController = TextEditingController();
    _idNumberController = TextEditingController();
    _surgeryTypeController = TextEditingController();
    _loadAgentConstants();
    _loadEditData();
  }

  void _loadEditData() {
    // Check if we're in edit mode
    final caseProvider = context.read<CaseProvider>();
    // Prefer explicit widget.caseData if provided, otherwise fall back to provider
    final CaseHistoryItem? editCase = widget.caseData ?? (caseProvider.isEditMode ? caseProvider.currentCase : null);
    
    if (editCase != null) {
      // EDIT MODE: Load provided case data
      final caseData = editCase;
      _patientNameController.text = caseData.patientName;
      _idNumberController.text = caseData.idNumber;
      _surgeryTypeController.text = caseData.surgeryType;
      _selectedAgent = caseData.agent;
      _selectedDate = caseData.date;
      
      // Set error states to false initially
      setState(() {
        _patientNameError = false;
        _idNumberError = false;
        _surgeryTypeError = false;
      });
    } else {
      // NEW CASE MODE: Explicitly clear all fields and reset to defaults
      print('📝 New Case Mode - clearing all fields and resetting state');
      _patientNameController.clear();
      _idNumberController.clear();
      _surgeryTypeController.clear();
      _selectedAgent = 'Isoflurane';
      _selectedDate = DateTime.now();
      
      setState(() {
        _patientNameError = false;
        _idNumberError = false;
        _surgeryTypeError = false;
      });
    }
  }

  Future<void> _loadAgentConstants() async {
    try {
      final agents = await AgentConstantsService.getAllAgents();

      if (agents.isNotEmpty) {
        final Map<String, Map<String, String>> fetched = {};

        for (final agent in agents) {
          final String? name = agent['agentName']?.toString();
          if (name == null || name.isEmpty) {
            continue;
          }

          fetched[name] = {
            'molecularMass': agent['molecularMass']?.toString() ?? '--',
            'liquidToVaporConstant': agent['liquidToVaporConstant']?.toString() ?? '--',
            'density': agent['density']?.toString() ?? '--',
          };
          }
        if (mounted && fetched.isNotEmpty) {
          setState(() {
            _agentConstants
              ..clear()
              ..addAll(fetched);
            if (!_agentConstants.containsKey(_selectedAgent)) {
              _selectedAgent = _agentConstants.keys.first;
            }
          });
        }
      }
    } catch (_) {
      // Keep fallback defaults when backend is unavailable.
    } finally {
      if (mounted) {
        setState(() => _isLoadingConstants = false);
      }
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _idNumberController.dispose();
    _surgeryTypeController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    setState(() {
      _patientNameError = _patientNameController.text.isEmpty;
      _idNumberError = _idNumberController.text.isEmpty;
      _surgeryTypeError = _surgeryTypeController.text.isEmpty;
    });

    return !(_patientNameError || _idNumberError || _surgeryTypeError);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _navigateBackToFreshLogin() async {
    ScaffoldMessenger.of(context).clearSnackBars();
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _openHistoryDialog() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CaseHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final constants = _agentConstants[_selectedAgent] ?? {
      'molecularMass': '--',
      'liquidToVaporConstant': '--',
      'density': '--',
    };
    final agents = _agentConstants.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: false,
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () async {
              if (_validateForm()) {
                final caseProvider = context.read<CaseProvider>();
                final isEditMode = caseProvider.isEditMode;
                
                // If editing, pass the induction data forward
                final inductionFGF = isEditMode ? caseProvider.currentCase!.inductionFGF : 0.0;
                final inductionConc = isEditMode ? caseProvider.currentCase!.inductionConcentration : 0.0;
                final inductionTime = isEditMode ? caseProvider.currentCase!.inductionTime : 0.0;
                final List<Map<String, double>> maintenanceRows = isEditMode
                  ? caseProvider.currentCase!.maintenanceRows
                  : <Map<String, double>>[];
                
                final result = await Navigator.push<bool?>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConsumptionCalculatorScreen(
                      patientName: _patientNameController.text.trim(),
                      idNumber: _idNumberController.text.trim(),
                      date: _selectedDate,
                      surgeryType: _surgeryTypeController.text.trim(),
                      agent: _selectedAgent,
                      lvConstant: double.tryParse(constants['molecularMass'] ?? '') ?? 0,
                      liquidVaporConstant:
                          double.tryParse(constants['liquidToVaporConstant'] ?? '') ?? 1,
                      density: double.tryParse(constants['density'] ?? '') ?? 1,
                      inductionFGF: inductionFGF,
                      inductionConcentration: inductionConc,
                      inductionTime: inductionTime,
                      maintenanceRows: maintenanceRows,
                      initialWeight: isEditMode ? caseProvider.currentCase?.initialWeight : null,
                      finalWeight: isEditMode ? caseProvider.currentCase?.finalWeight : null,
                    ),
                  ),
                );

                if (result == true) {
                  if (mounted) Navigator.pop(context, true);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              context.watch<CaseProvider>().isEditMode ? 'Update' : 'Next',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            AppHeader(
              title: 'New Case',
              breadcrumb: 'Home • New Case',
              showBack: true,
              onBack: () => Navigator.pop(context),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppHeaderActionButton(
                    icon: Icons.history,
                    tooltip: 'View History',
                    onTap: _openHistoryDialog,
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                // Patient Information Section
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
                        'Patient Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Patient Name
                      _buildFormField(
                        label: 'Patient Name',
                        hint: 'Enter patient name',
                        controller: _patientNameController,
                        icon: Icons.person_outline,
                        isError: _patientNameError,
                        errorMessage: _patientNameError ? 'Patient name is required' : null,
                      ),

                      const SizedBox(height: 16),

                      // ID Number
                      _buildFormField(
                        label: 'ID Number',
                        hint: 'Enter ID number',
                        controller: _idNumberController,
                        icon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                        isError: _idNumberError,
                        errorMessage: _idNumberError ? 'ID number is required' : null,
                      ),

                      const SizedBox(height: 16),

                      // Date
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date',
                            style: TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFDCE6F2),
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDate(_selectedDate),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1F2937),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Surgery Type
                      _buildFormField(
                        label: 'Surgery Type',
                        hint: 'Enter surgery type',
                        controller: _surgeryTypeController,
                        icon: Icons.local_hospital_outlined,
                        isError: _surgeryTypeError,
                        errorMessage: _surgeryTypeError ? 'Surgery type is required' : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Anesthetic Agent Section
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
                        'Anesthetic Agent',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Agent',
                            style: TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFDCE6F2),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: DropdownButton<String>(
                              value: _selectedAgent,
                              isExpanded: true,
                              underline: const SizedBox(),
                              hint: const Text('Select Agent'),
                              items: agents.map((String agent) {
                                return DropdownMenuItem<String>(
                                  value: agent,
                                  child: Text(
                                    agent,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1F2937),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (_isLoadingConstants) {
                                  return;
                                }
                                if (newValue != null) {
                                  setState(() {
                                    _selectedAgent = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Agent Constants Section
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
                        'Agent Constants',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Constants cards
                      SizedBox(
                        height: 120,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildConstantCard(
                                label: 'Molecular Mass',
                                value: constants['molecularMass'] ?? '--',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildConstantCard(
                                label: 'Liquid to\nVapor Constant',
                                value: constants['liquidToVaporConstant'] ?? '--',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildConstantCard(
                                label: 'Density',
                                value: constants['density'] ?? '--',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
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
              prefixIcon: Icon(
                icon,
                size: 18,
                color: hasError ? const Color(0xFFDC2626) : const Color(0xFF9CA3AF),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
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

  Widget _buildConstantCard({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD1E3FF)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
              fontFamily: 'Inter',
              height: 1.2,
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

