import 'package:flutter/material.dart';
import 'dart:convert';

import '../config/app_colors.dart';
import '../models/case_history_item.dart';
import '../services/case_service.dart';
import '../services/export_service.dart';
import '../widgets/app_header.dart';
import 'profile_screen.dart';
// macmind_design not used directly in this file

/// Full-page Case History Screen
class CaseHistoryScreen extends StatefulWidget {
  const CaseHistoryScreen({super.key});

  @override
  State<CaseHistoryScreen> createState() => _CaseHistoryScreenState();
}

class _CaseHistoryScreenState extends State<CaseHistoryScreen> {
  late Future<List<CaseHistoryItem>> _casesFuture;

  @override
  void initState() {
    super.initState();
    _casesFuture = _fetchCases();
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
      patientName: (json['patient_name'] ?? json['patientName'] ?? '').toString(),
      idNumber: (json['patient_id'] ?? json['idNumber'] ?? '').toString(),
      date: parsedDate,
      surgeryType: (json['surgery_type'] ?? json['surgeryType'] ?? '').toString(),
      agent: (json['anesthetic_agent'] ?? json['selectedAgent'] ?? '').toString(),
      freshGasFlow: legacyFGF,
      dialConcentration: legacyConc,
      timeMinutes: legacyTime,
      initialWeight: asNullableDouble(json['initial_weight'] ?? json['initialWeight']),
      finalWeight: asNullableDouble(json['final_weight'] ?? json['finalWeight']),
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
            onBack: () => Navigator.pop(context),
            onProfileTap: () {
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
              child: FutureBuilder<List<CaseHistoryItem>>(
                future: _casesFuture,
                builder: (context, snapshot) {
                  final savedCases = snapshot.data ?? <CaseHistoryItem>[];

                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: savedCases.isEmpty
                          ? null
                          : () async {
                              try {
                                final path = await ExportService.exportAllAsCsv(
                                  savedCases,
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
                  );
                },
              ),
            ),

            // Case list
            Expanded(
              child: FutureBuilder<List<CaseHistoryItem>>(
                future: _casesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  final savedCases = snapshot.data ?? <CaseHistoryItem>[];

                  if (savedCases.isEmpty) {
                    return const Center(
                      child: Text(
                        'No saved cases yet.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Inter',
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: savedCases.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _HistoryCard(item: savedCases[index]);
                    },
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

  const _HistoryCard({required this.item});

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
            children: [
              Expanded(
                child: Text(
                  item.patientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Text(
                _displayDate(item.date),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'ID: ${item.idNumber}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontFamily: 'Inter',
            ),
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
