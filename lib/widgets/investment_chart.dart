import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../features/funds/data/models/investment_return.dart';
import '../providers/investment_returns_service_provider.dart';

class InvestmentChart extends ConsumerWidget {
  final List<InvestmentReturn> returns;
  final ReturnType type;

  const InvestmentChart({
    super.key,
    required this.returns,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (returns.isEmpty) {
      return const Center(child: Text("No data available"));
    }

    final touchedIndex = ref.watch(touchedBarIndexProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // const chartHeight = 200.0;
        // const barWidth = 40.0;

        return BarChart(
          BarChartData(
            maxY: 100,
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => const Color(0xFFE3F3FE),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final returnData = returns[group.x.toInt()];
                  return BarTooltipItem(
                    "${returnData.period}\n${returnData.percentage.toStringAsFixed(2)}%",
                    const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
              touchCallback: (event, response) {
                if (!event.isInterestedForInteractions ||
                    response == null ||
                    response.spot == null) {
                  ref.read(touchedBarIndexProvider.notifier).state = null;
                  return;
                }
                ref.read(touchedBarIndexProvider.notifier).state =
                    response.spot!.touchedBarGroupIndex;
              },
            ),
            barGroups: returns.asMap().entries.map((entry) {
              final index = entry.key;
              final returnData = entry.value;
              final isTouched = index == touchedIndex;

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: returnData.percentage > 100 ? 100 : returnData.percentage,
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
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (value) => FlLine(
                color: const Color(0xFFD9D9D9),
                strokeWidth: 1,
                dashArray: [6, 4],
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 20,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()}%',
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                  reservedSize: 36,
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < returns.length) {
                      return Text(
                        returns[value.toInt()].period,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
          ),
        );
      },
    );
  }
}