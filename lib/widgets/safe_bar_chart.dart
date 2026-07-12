// lib/widgets/safe_bar_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SafeBarChart extends StatelessWidget {
  final List<BarChartGroupData> barGroups;
  final BarChartData Function(List<BarChartGroupData>)? dataBuilder;

  const SafeBarChart({
    super.key,
    required this.barGroups,
    this.dataBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (barGroups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text("Sem dados para exibir no gráfico"),
          ],
        ),
      );
    }

    final data = dataBuilder?.call(barGroups) ?? BarChartData(barGroups: barGroups);

    return BarChart(data);
  }
}