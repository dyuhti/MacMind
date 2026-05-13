import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../models/case_history_item.dart';
import '../services/case_service.dart';
import '../services/auth_service.dart';
import '../services/export_service.dart';
import '../widgets/app_header.dart';
import '../providers/case_provider.dart';
import 'settings_screen.dart';
import 'new_case_screen.dart';
import 'case_details_screen.dart';
// macmind_design not used directly in this file

/// Full-page Case History Screen
class CaseHistoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onProfileTap;

  const CaseHistoryScreen({super.key, this.onBack, this.onProfileTap});

  @override
  State<CaseHistoryScreen> createState() => _CaseHistoryScreenState();
}

class _CaseHistoryScreenState extends State<CaseHistoryScreen> {
  late Future<List<CaseHistoryItem>> _casesFuture;
  final TextEditingController _searchController = TextEditingController();
  List<CaseHistoryItem> allCases = <CaseHistoryItem>[];
  List<CaseHistoryItem> filteredCases = <CaseHistoryItem>[];
  bool _isLoadingCases = true;

  @override
  void initState() {
    super.initState();
    _casesFuture = _fetchCases();
    _searchController.addListener(_onSearchChanged);
    _loadCases();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applySearchFilter(_searchController.text);
  }

  String _searchDate(DateTime date) {
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

  void _applySearchFilter(String query) {
    final normalized = query.toLowerCase().trim();

    setState(() {
      if (normalized.isEmpty) {
        filteredCases = List<CaseHistoryItem>.from(allCases);
        return;
      }

      filteredCases = allCases.where((caseItem) {
        final patientName = caseItem.patientName.toLowerCase();
        final patientId = caseItem.idNumber.toLowerCase();
        final surgeryType = caseItem.surgeryType.toLowerCase();
        final agent = caseItem.agent.toLowerCase();
        final displayDate = _searchDate(caseItem.date).toLowerCase();
        final isoDate =
            '${caseItem.date.year}-${caseItem.date.month.toString().padLeft(2, '0')}-${caseItem.date.day.toString().padLeft(2, '0')}';

        return patientName.toLowerCase().contains(normalized) ||
            patientId.toLowerCase().contains(normalized) ||
            surgeryType.toLowerCase().contains(normalized) ||
            agent.toLowerCase().contains(normalized) ||
            displayDate.toLowerCase().contains(normalized) ||
            isoDate.toLowerCase().contains(normalized);
      }).toList();
    });
  }

  Future<void> _loadCases() async {
    final cases = await _casesFuture;
    if (!mounted) {
      return;
    }

    setState(() {
      allCases = cases;
      filteredCases = List<CaseHistoryItem>.from(cases);
      _isLoadingCases = false;
    });
  }

  Future<List<CaseHistoryItem>> _fetchCases() async {
    try {
      final result = await CaseService.getAllCases();
      
      // Handle authentication errors
      if (result['statusCode'] == 401) {
        // Token expired or invalid - redirect to login
        if (!mounted) return <CaseHistoryItem>[];
        
        // Clear auth session and redirect to login
        await AuthService.logout();
        Navigator.of(context).pushReplacementNamed('/login');
        return <CaseHistoryItem>[];
      }
      
      if (result['success'] != true) {
        if (!mounted) return <CaseHistoryItem>[];
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']?.toString() ?? 'Failed to fetch cases'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
        return <CaseHistoryItem>[];
      }

      final decoded = result['cases'];
      if (decoded is! List) return <CaseHistoryItem>[];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_mapJsonToHistoryItem)
          .toList();
    } catch (_) {
      return <CaseHistoryItem>[];
    }
  }

  void _openEditCase(CaseHistoryItem caseData) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _doOpenEditCase(caseData);
    });
  }

  Future<void> _doOpenEditCase(CaseHistoryItem caseData) async {
    // Ensure provider knows we're editing this case and log weight for debugging
    context.read<CaseProvider>().startEditMode(caseData);
    print('🔎 Editing case weight: initial=${caseData.initialWeight}, final=${caseData.finalWeight}');

    final result = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(builder: (_) => NewCaseScreen(caseData: caseData)),
    );

    // If the edit flow signalled success, refresh the list
    if (result == true) {
      // Re-fetch cases from API and update local list
      final fresh = await _fetchCases();
      if (!mounted) return;
      setState(() {
        allCases = fresh;
        filteredCases = List<CaseHistoryItem>.from(fresh);
      });
      _applySearchFilter(_searchController.text);
    }
  }

  Future<void> _deleteCase(CaseHistoryItem caseData) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this case?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFDC2626)),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true || caseData.id == null) {
      return;
    }

    final parsedId = int.tryParse(caseData.id!);
    if (parsedId == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete case: invalid case ID'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final result = await CaseService.deleteCase(parsedId);
    if (!mounted) {
      return;
    }

    // Handle authentication errors
    if (result['statusCode'] == 401) {
      // Token expired or invalid - redirect to login
      await AuthService.logout();
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }
    
    // Handle authorization errors
    if (result['statusCode'] == 403) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to delete this case'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (result['success'] == true) {
      setState(() {
        allCases.removeWhere((entry) => entry.id == caseData.id);
      });
      _applySearchFilter(_searchController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Case deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']?.toString() ?? 'Failed to delete case'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  CaseHistoryItem _mapJsonToHistoryItem(Map<String, dynamic> json) {
    double asDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value.trim()) ?? 0.0;
      }
      return 0.0;
    }

    double? asNullableDouble(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value.trim());
      }
      return null;
    }

    final createdAt = (json['created_at'] ?? json['createdAt'])?.toString();
    final parsedDate = createdAt != null
        ? DateTime.tryParse(createdAt) ?? DateTime.now()
        : DateTime.now();

    final legacyFGF = asDouble(json['fresh_gas_flow'] ?? json['freshGasFlow']);
    final legacyConc = asDouble(json['dial_concentration'] ?? json['dialConcentration']);
    final legacyTime = asDouble(json['time_minutes'] ?? json['timeMinutes']);

    // Parse maintenance rows data (can be List or JSON string)
    final maintenanceRows = <Map<String, double>>[];
    var maintenanceDataDynamic = json['maintenance_rows'] ?? json['maintenance'];
    
    // If it's a JSON string, parse it
    if (maintenanceDataDynamic is String) {
      try {
        maintenanceDataDynamic = jsonDecode(maintenanceDataDynamic);
      } catch (_) {
        maintenanceDataDynamic = [];
      }
    }
    
    if (maintenanceDataDynamic is List) {
      for (final entry in maintenanceDataDynamic) {
        if (entry is Map) {
          final row = Map<String, dynamic>.from(entry);
          maintenanceRows.add({
            'rowNumber': asDouble(row['rowNumber']),
            'fgf': asDouble(row['fgf']),
            'concentration': asDouble(row['concentration']),
            'time': asDouble(row['time']),
          });
        }
      }
    }

    // Parse row-wise calculation outputs (can be List or JSON string)
    final maintenanceCalculations = <Map<String, double>>[];
    var maintenanceCalcDynamic =
        json['maintenance_calculations'] ?? json['maintenanceCalculations'];
    
    // If it's a JSON string, parse it
    if (maintenanceCalcDynamic is String) {
      try {
        maintenanceCalcDynamic = jsonDecode(maintenanceCalcDynamic);
      } catch (_) {
        maintenanceCalcDynamic = [];
      }
    }
    
    if (maintenanceCalcDynamic is List) {
      for (final entry in maintenanceCalcDynamic) {
        if (entry is Map) {
          final row = Map<String, dynamic>.from(entry);
          maintenanceCalculations.add({
            'row': asDouble(row['row']),
            'biro': asDouble(row['biro']),
            'dion': asDouble(row['dion']),
          });
        }
      }
    }

    return CaseHistoryItem(
      id: (json['id'] ?? json['case_id']).toString(),
      patientName: (json['patient_name'] ?? json['patientName'] ?? '').toString(),
      idNumber: (json['patient_id'] ?? json['idNumber'] ?? '').toString(),
      date: parsedDate,
      surgeryType: (json['surgery_type'] ?? json['surgeryType'] ?? '').toString(),
      agent: (json['anesthetic_agent'] ?? json['selectedAgent'] ?? '').toString(),
      freshGasFlow: legacyFGF,
      dialConcentration: legacyConc,
      timeMinutes: legacyTime,
      // Support both flat fields and nested 'weight' object
      initialWeight: asNullableDouble(
        (json['weight'] != null && json['weight'] is Map)
        ? (json['weight']['initialWeight'] ?? json['weight']['initial_weight'])
        : (json['initial_weight'] ?? json['initialWeight']),
      ),
      finalWeight: asNullableDouble(
        (json['weight'] != null && json['weight'] is Map)
        ? (json['weight']['finalWeight'] ?? json['weight']['final_weight'])
        : (json['final_weight'] ?? json['finalWeight']),
      ),
      birosFormulaMl: asDouble(json['biro_formula'] ?? json['biroFormula']).toDouble(),
      dionsFormulaMl: asDouble(json['dion_formula'] ?? json['dionFormula']).toDouble(),
      weightBasedMl: asDouble(json['weight_based'] ?? json['weightBased']).toDouble(),
      notes: (json['notes'] ?? '').toString(),
      savedAt: parsedDate,
      inductionFGF: asDouble(json['induction_fgf'] ?? json['inductionFGF']),
      inductionConcentration: asDouble(
        json['induction_concentration'] ?? json['inductionConcentration'],
      ),
      inductionTime: asDouble(json['induction_time'] ?? json['inductionTime']),
      maintenanceRows: maintenanceRows,
      inductionBiro: asDouble(json['induction_biro'] ?? json['inductionBiro']),
      inductionDion: asDouble(json['induction_dion'] ?? json['inductionDion']),
      maintenanceCalculations: maintenanceCalculations,
      finalBiro: asDouble(json['final_biro'] ?? json['finalBiro']),
      finalDion: asDouble(json['final_dion'] ?? json['finalDion']),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: false,
      body: Column(
        children: [
          AppHeader(
            title: 'Case History',
            breadcrumb: 'Home • New Case • History',
            showBack: true,
            onBack: widget.onBack ?? () => Navigator.pop(context),
            onProfileTap: widget.onProfileTap ?? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
            // Header with export button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCE6F2)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Inter',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search cases...',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                      fontFamily: 'Inter',
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Color(0xFF6B7280),
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: allCases.isEmpty
                      ? null
                      : () async {
                          try {
                            final path = await ExportService.exportAllAsCsv(
                              allCases,
                            );
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('All cases exported to $path'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (_) {
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to export all cases'),
                                backgroundColor: Color(0xFFDC2626),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: const Color(0xFFBFD3EC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(
                    Icons.file_download_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Export All to Excel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ),

            // Case list
            Expanded(
              child: _isLoadingCases
                  ? Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : allCases.isEmpty
                      ? const Center(
                          child: Text(
                            'No saved cases yet.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                              fontFamily: 'Inter',
                            ),
                          ),
                        )
                      : filteredCases.isEmpty
                          ? const Center(
                              child: Text(
                                'No matching cases found',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: filteredCases.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final caseItem = filteredCases[index];
                                return _HistoryCard(
                                  item: caseItem,
                                  onEdit: () => _openEditCase(caseItem),
                                  onDelete: () => _deleteCase(caseItem),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    ),
  ],
),
);
  }
}

class _HistoryCard extends StatelessWidget {
  final CaseHistoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  String _displayDate(DateTime date) {
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

  void _openDetailsPage(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: CaseDetailsScreen(
              item: item,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          return SlideTransition(position: slide, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetailsPage(context),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDCE6F2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ID: ${item.idNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _displayDate(item.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.keyboard_arrow_right_rounded,
                size: 22,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
