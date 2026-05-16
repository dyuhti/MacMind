import 'package:flutter/material.dart';

import '../models/case_history_item.dart';
import '../widgets/app_header.dart';

class CaseDetailsScreen extends StatelessWidget {
  final CaseHistoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CaseDetailsScreen({
    super.key,
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

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFE7EDF5), height: 1),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
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
          AppHeader(
            title: 'Case Details',
            breadcrumb: 'Case History • Case Details',
            showBack: true,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  _sectionCard(
                    title: 'Patient Information',
                    children: [
                      _kv('Patient Name', item.patientName),
                      _kv('Patient ID', item.idNumber),
                      _kv('Date', _displayDate(item.date)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Surgery Details',
                    children: [
                      _kv('Surgery Type', item.surgeryType),
                      _kv('Agent', item.agent),
                      _kv('Fresh Gas Flow', '${item.freshGasFlow.toStringAsFixed(2)} L/min'),
                      _kv('Dial Concentration', '${item.dialConcentration.toStringAsFixed(2)} %'),
                      _kv('Time', '${item.timeMinutes.toStringAsFixed(2)} min'),
                      _kv(
                        'Initial Weight',
                        item.initialWeight != null ? '${item.initialWeight!.toStringAsFixed(2)} g' : '--',
                      ),
                      _kv(
                        'Final Weight',
                        item.finalWeight != null ? '${item.finalWeight!.toStringAsFixed(2)} g' : '--',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Calculation Results',
                    children: [
                      _kv('Biro Formula', '${item.birosFormulaMl.toStringAsFixed(1)} mL'),
                      _kv('Dion Formula', '${item.dionsFormulaMl.toStringAsFixed(1)} mL'),
                      _kv('Weight-Based', '${item.weightBasedMl.toStringAsFixed(1)} mL'),
                      _kv('Final Biro', '${item.finalBiro.toStringAsFixed(1)} mL'),
                      _kv('Final Dion', '${item.finalDion.toStringAsFixed(1)} mL'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Induction Details',
                    children: [
                      _kv('FGF', '${item.inductionFGF.toStringAsFixed(2)} L'),
                      _kv('Concentration', '${item.inductionConcentration.toStringAsFixed(2)} %'),
                      _kv('Time', '${item.inductionTime.toStringAsFixed(2)} min'),
                      _kv('Biro', '${item.inductionBiro.toStringAsFixed(1)} mL'),
                      _kv('Dion', '${item.inductionDion.toStringAsFixed(1)} mL'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Maintenance Details',
                    children: [
                      if (item.maintenanceRows.isEmpty)
                        const Text(
                          'No maintenance rows recorded.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Inter',
                          ),
                        )
                      else
                        ...item.maintenanceRows.asMap().entries.map((entry) {
                          final rowIndex = entry.key + 1;
                          final row = entry.value;
                          return _kv(
                            'Row $rowIndex',
                            'FGF ${row['fgf']?.toStringAsFixed(2) ?? '0.00'} L, '
                            'Conc ${row['concentration']?.toStringAsFixed(2) ?? '0.00'} %, '
                            'Time ${row['time']?.toStringAsFixed(2) ?? '0.00'} min',
                          );
                        }),
                      if (item.maintenanceCalculations.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(color: Color(0xFFE7EDF5), height: 1),
                        const SizedBox(height: 8),
                        ...item.maintenanceCalculations.map((calc) {
                          final row = (calc['row'] ?? 0).toInt();
                          return _kv(
                            'Calculated Row $row',
                            'Biro ${calc['biro']?.toStringAsFixed(1) ?? '0.0'} mL, '
                            'Dion ${calc['dion']?.toStringAsFixed(1) ?? '0.0'} mL',
                          );
                        }),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'AI Clinical Insights',
                    children: const [
                      Text(
                        'AI insights are not stored in this history record.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Notes',
                    children: [
                      Text(
                        item.notes.trim().isEmpty ? 'No notes provided.' : item.notes,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1F2937),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onEdit();
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFD1D9E6)),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onDelete();
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
