import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../features/funds/data/models/investment_performance.dart';

class PerformanceChart extends StatefulWidget {
  final List<InvestmentPerformance> performance;

  const PerformanceChart({super.key, required this.performance});

  @override
  State<PerformanceChart> createState() => _PerformanceChartState();
}

class _PerformanceChartState extends State<PerformanceChart> {
  int? _touchedBarIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.performance.isEmpty) {
      return const Center(child: Text("No data available"));
    }

    return BarChart(
      BarChartData(
        maxY: 100,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => const Color(0xFFE3F3FE),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final performance = widget.performance[group.x.toInt()];
              return BarTooltipItem(
                '${performance.fundReturn.toStringAsFixed(2)}%',
                const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  barTouchResponse == null ||
                  barTouchResponse.spot == null) {
                _touchedBarIndex = -1;
                return;
              }
              _touchedBarIndex = barTouchResponse.spot!.touchedBarGroupIndex;
            });
          },
        ),
        barGroups: widget.performance.asMap().entries.map((entry) {
          final i = entry.key;
          final perf = entry.value;
          final isTouched = i == _touchedBarIndex;

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: perf.fundReturn,
                color: isTouched
                    ? const Color(0xFF0060A6).withOpacity(0.8)
                    : const Color(0xFF0060A6),
                width: isTouched ? 45 : 40,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
            showingTooltipIndicators: isTouched ? [0] : [],
          );
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false, // Remove vertical lines
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
              dashArray: [5, 5], // Creates dashed lines -----
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < widget.performance.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.performance[value.toInt()].period,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  "${v.toInt()}%",
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ),
              reservedSize: 35,
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}