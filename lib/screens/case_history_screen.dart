import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../models/case_history_item.dart';
import '../services/case_service.dart';
import '../services/export_service.dart';
import '../widgets/app_header.dart';
import '../providers/case_provider.dart';
import 'profile_screen.dart';
import 'new_case_screen.dart';
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
  List<CaseHistoryItem> _savedCases = <CaseHistoryItem>[];
  bool _isLoadingCases = true;

  @override
  void initState() {
    super.initState();
    _casesFuture = _fetchCases();
    _loadCases();
  }

  Future<void> _loadCases() async {
    final cases = await _casesFuture;
    if (!mounted) {
      return;
    }

    setState(() {
      _savedCases = cases;
      _isLoadingCases = false;
    });
  }

  Future<List<CaseHistoryItem>> _fetchCases() async {
    try {
      final result = await CaseService.getAllCases();
      if (result['success'] != true) {
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
        _savedCases = fresh;
      });
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

    if (result['success'] == true) {
      setState(() {
        _savedCases.removeWhere((entry) => entry.id == caseData.id);
      });
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
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
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
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _savedCases.isEmpty
                      ? null
                      : () async {
                          try {
                            final path = await ExportService.exportAllAsCsv(
                              _savedCases,
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
                  : _savedCases.isEmpty
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
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _savedCases.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final caseItem = _savedCases[index];
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

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            k,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontFamily: 'Inter',
            ),
          ),
          Text(
            v,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${item.idNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _displayDate(item.date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!context.mounted) {
                              return;
                            }
                            onEdit();
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _kv('Surgery', item.surgeryType),
          _kv('Agent', item.agent),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFE5EAF0), height: 1),
          const SizedBox(height: 10),
          const Text(
            'Induction:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          _kv('FGF', '${item.inductionFGF.toStringAsFixed(2)} L'),
          _kv('Concentration', '${item.inductionConcentration.toStringAsFixed(2)} %'),
          _kv('Time', '${item.inductionTime.toStringAsFixed(2)} min'),
          _kv('Biro', '${item.inductionBiro.toStringAsFixed(1)} mL'),
          _kv('Dion', '${item.inductionDion.toStringAsFixed(1)} mL'),
          if (item.maintenanceRows.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Maintenance:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 6),
            ...item.maintenanceRows.asMap().entries.map((e) {
              final rowIdx = e.key + 1;
              final row = e.value;
              return _kv(
                'Row $rowIdx',
                'FGF: ${row['fgf']?.toStringAsFixed(2) ?? "0.00"} L, '
                'Conc: ${row['concentration']?.toStringAsFixed(2) ?? "0.00"}%, '
                'Time: ${row['time']?.toStringAsFixed(2) ?? "0.00"}m',
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}
