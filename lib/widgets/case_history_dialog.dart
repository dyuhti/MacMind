import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_colors.dart';
import '../config/api_config.dart';
import '../models/case_history_item.dart';
import '../services/auth_service.dart';
import '../services/export_service.dart';

Future<void> showCaseHistoryDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return const Dialog(
        insetPadding: EdgeInsets.all(8),
        child: _CaseHistoryDialogContent(),
      );
    },
  );
}

class _CaseHistoryDialogContent extends StatefulWidget {
  const _CaseHistoryDialogContent();

  @override
  State<_CaseHistoryDialogContent> createState() =>
      _CaseHistoryDialogContentState();
}

class _CaseHistoryDialogContentState extends State<_CaseHistoryDialogContent> {
  late Future<List<CaseHistoryItem>> _casesFuture;

  @override
  void initState() {
    super.initState();
    _casesFuture = _fetchCases();
  }

  Future<List<CaseHistoryItem>> _fetchCases() async {
    try {
      final userEmail = await AuthService.getLoggedInEmail();
      if (userEmail == null || userEmail.isEmpty) {
        return <CaseHistoryItem>[];
      }

      final encodedEmail = Uri.encodeComponent(userEmail);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/cases/$encodedEmail'),
        headers: const {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        return <CaseHistoryItem>[];
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return <CaseHistoryItem>[];
      }

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
      return null;
    }

    final createdAt = json['createdAt']?.toString();
    final parsedDate = createdAt != null
        ? DateTime.tryParse(createdAt) ?? DateTime.now()
        : DateTime.now();

    // Parse induction data (fallback to legacy flat fields)
    final inductionDataDynamic = json['induction'];
    final inductionData = inductionDataDynamic is Map
      ? Map<String, dynamic>.from(inductionDataDynamic)
      : null;

    final legacyFGF = asDouble(json['freshGasFlow']);
    final legacyConc = asDouble(json['dialConcentration']);
    final legacyTime = asDouble(json['timeMinutes']);

    final inductionFGF = inductionData != null
      ? asDouble(inductionData['fgf'])
      : legacyFGF;
    final inductionConc = inductionData != null
      ? asDouble(inductionData['concentration'])
      : legacyConc;
    final inductionTime = inductionData != null
      ? asDouble(inductionData['time'])
      : legacyTime;

    // Parse maintenance rows data
    final maintenanceRows = <Map<String, double>>[];
    final maintenanceDataDynamic = json['maintenance'];
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

    // Parse row-wise calculation outputs
    final maintenanceCalculations = <Map<String, double>>[];
    final maintenanceCalcDynamic = json['maintenanceCalculations'];
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
      patientName: (json['patientName'] ?? '').toString(),
      idNumber: (json['idNumber'] ?? '').toString(),
      date: parsedDate,
      surgeryType: (json['surgeryType'] ?? '').toString(),
      agent: (json['selectedAgent'] ?? '').toString(),
      freshGasFlow: legacyFGF,
      dialConcentration: legacyConc,
      timeMinutes: legacyTime,
      initialWeight: asNullableDouble(json['initialWeight']),
      finalWeight: asNullableDouble(json['finalWeight']),
      birosFormulaMl: asDouble(json['biroFormula']).toDouble(),
      dionsFormulaMl: asDouble(json['dionFormula']).toDouble(),
      weightBasedMl: asDouble(json['weightBased']).toDouble(),
      notes: (json['notes'] ?? '').toString(),
      savedAt: parsedDate,
      inductionFGF: inductionFGF,
      inductionConcentration: inductionConc,
      inductionTime: inductionTime,
      maintenanceRows: maintenanceRows,
      inductionBiro: asDouble(json['inductionBiro']),
      inductionDion: asDouble(json['inductionDion']),
      maintenanceCalculations: maintenanceCalculations,
      finalBiro: asDouble(json['finalBiro']),
      finalDion: asDouble(json['finalDion']),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.82,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Case History',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                          fontFamily: 'Inter',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'All saved cases from MongoDB Atlas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: FutureBuilder<List<CaseHistoryItem>>(
              future: _casesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }

                final savedCases = snapshot.data ?? <CaseHistoryItem>[];

                return SizedBox(
                  width: double.infinity,
                  height: 50,
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
                                ),
                              );
                            } catch (_) {
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to export all cases'),
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
          const SizedBox(height: 8),
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
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: savedCases.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _HistoryCard(item: savedCases[index]);
                  },
                );
              },
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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
          const SizedBox(height: 4),
          Text(
            'ID: ${item.idNumber}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          _kv('Surgery', item.surgeryType),
          _kv('Agent', item.agent),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFE5EAF0), height: 1),
          const SizedBox(height: 8),
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
          _kv(
            'FGF',
            '${item.inductionFGF.toStringAsFixed(2)} L',
          ),
          _kv(
            'Concentration',
            '${item.inductionConcentration.toStringAsFixed(2)} %',
          ),
          _kv('Time', '${item.inductionTime.toStringAsFixed(2)} min'),
          _kv('Biro', '${item.inductionBiro.toStringAsFixed(1)} mL'),
          _kv('Dion', '${item.inductionDion.toStringAsFixed(1)} mL'),
          if (item.maintenanceRows.isNotEmpty) ...[
            const SizedBox(height: 8),
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
              final rowNumber = (row['rowNumber'] ?? rowIdx.toDouble()).toInt();
              final calc = item.maintenanceCalculations.firstWhere(
                (c) => (c['row'] ?? -1).toInt() == rowNumber,
                orElse: () => const <String, double>{},
              );
              final rowBiro = calc['biro'] ?? 0.0;
              final rowDion = calc['dion'] ?? 0.0;
              final fgf = row['fgf']?.toStringAsFixed(2) ?? '0.00';
              final conc = row['concentration']?.toStringAsFixed(2) ?? '0.00';
              final time = row['time']?.toStringAsFixed(2) ?? '0.00';
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFBFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: Row(
                  children: [
                    Text(
                      'R$rowNumber',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A90E2),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'FGF: $fgf L | Conc: $conc % | Time: $time min\nBiro: ${rowBiro.toStringAsFixed(1)} mL | Dion: ${rowDion.toStringAsFixed(1)} mL',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF374151),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 8),
          _kv(
            'Initial Weight',
            item.initialWeight != null
                ? '${item.initialWeight!.toStringAsFixed(0)} kg'
                : '-',
          ),
          _kv(
            'Final Weight',
            item.finalWeight != null
                ? '${item.finalWeight!.toStringAsFixed(0)} kg'
                : '-',
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFE5EAF0), height: 1),
          const SizedBox(height: 8),
          const Text(
            'Results (ml):',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _resultTile(
                    "Biro's",
                    item.birosFormulaMl.toStringAsFixed(1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _resultTile(
                    "Dion's",
                    item.dionsFormulaMl.toStringAsFixed(1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _resultTile(
                    'Weight',
                    item.weightBasedMl.toStringAsFixed(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$key:',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
                fontFamily: 'Inter',
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1F2937),
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            softWrap: true,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4B5563),
              fontFamily: 'Inter',
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
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
