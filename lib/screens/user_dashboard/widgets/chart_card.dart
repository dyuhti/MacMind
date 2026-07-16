import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BarChartCard extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;
  final String barLabel;
  final Color barColor;

  const BarChartCard({
    super.key,
    required this.data,
    required this.title,
    required this.barLabel,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final limited = data.length > 14 ? data.sublist(data.length - 14) : data;
    final barGroups = <BarChartGroupData>[];
    double maxY = 1;

    for (var i = 0; i < limited.length; i++) {
      final d = limited[i];
      final cases = (d['cases'] as num?)?.toDouble() ?? 0;
      final oxygen = (d['oxygen'] as num?)?.toDouble() ?? 0;
      final total = cases + oxygen;
      if (total > maxY) maxY = total;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: cases,
              color: const Color(0xFF2563EB),
              width: 10,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            BarChartRodData(
              toY: oxygen,
              color: const Color(0xFF0D9488),
              width: 10,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Row(children: [
            _dot(const Color(0xFF2563EB)),
            const SizedBox(width: 4),
            const Text('Cases',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(width: 12),
            _dot(const Color(0xFF0D9488)),
            const SizedBox(width: 4),
            const Text('Oxygen',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ]),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                barGroups: barGroups,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final d = limited[groupIndex];
                      final label = rodIndex == 0 ? 'Cases' : 'Oxygen';
                      return BarTooltipItem(
                        '${d['date']}\n$label: ${rod.toY.toInt()}',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) =>
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

class PieChartCard extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;

  const PieChartCard({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF0D9488),
      const Color(0xFFF59E0B),
      const Color(0xFFE11D48),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: List.generate(data.length, (i) {
                        final val = (data[i]['count'] as num?)?.toDouble() ?? 0;
                        return PieChartSectionData(
                          value: val,
                          color: colors[i % colors.length],
                          radius: 40,
                          title: val > 0 ? '${val.toInt()}' : '',
                          titleStyle: const TextStyle(
                              color: Colors.white, fontSize: 11,
                              fontWeight: FontWeight.w700),
                        );
                      }),
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(data.length, (i) {
                    final d = data[i];
                    final pct = (d['percentage'] as num?)?.toDouble() ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _dot(colors[i % colors.length]),
                          const SizedBox(width: 6),
                          Text(
                            '${d['name'] ?? ''} (${pct.toStringAsFixed(1)}%)',
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) =>
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}
