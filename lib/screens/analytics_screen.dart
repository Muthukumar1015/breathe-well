import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/data_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  final DataProvider dataProvider;
  const AnalyticsScreen({super.key, required this.dataProvider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weeklyData = dataProvider.weeklyData;
    final healthScores = _deriveHealthScores(weeklyData);

    // Compute summary stats from real data
    final avgAqi = weeklyData.isEmpty ? 0 : weeklyData.map((d) => d['aqi'] as int).reduce((a, b) => a + b) ~/ weeklyData.length;
    final avgHealth = healthScores.isEmpty ? 0 : healthScores.map((d) => d['score'] as int).reduce((a, b) => a + b) ~/ healthScores.length;
    final highRiskDays = weeklyData.where((d) => (d['aqi'] as int) > 150).length;
    final bestDay = weeklyData.isEmpty
        ? 'N/A'
        : weeklyData.reduce((a, b) => (a['aqi'] as int) < (b['aqi'] as int) ? a : b)['day'] as String;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Analytics', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (dataProvider.isRealData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_done, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text('7-Day Live Data', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAqiSymptomsChart(theme, weeklyData)),
              const SizedBox(width: 20),
              Expanded(child: _buildHealthScoreChart(theme, healthScores)),
            ],
          ),

          const SizedBox(height: 24),

          // Insight card
          _buildInsightCard(theme, weeklyData),

          const SizedBox(height: 20),

          // Summary stats from real data
          Row(
            children: [
              _statCard(theme, 'Avg AQI', '$avgAqi', Icons.air, Colors.orange),
              const SizedBox(width: 16),
              _statCard(theme, 'Avg Health Score', '$avgHealth', Icons.favorite, Colors.red),
              const SizedBox(width: 16),
              _statCard(theme, 'High Risk Days', '$highRiskDays', Icons.warning_amber, Colors.deepOrange),
              const SizedBox(width: 16),
              _statCard(theme, 'Best Day', bestDay, Icons.star, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _deriveHealthScores(List<Map<String, dynamic>> weeklyData) {
    // Derive health score: inverse of AQI (higher AQI = lower health score)
    return weeklyData.map((d) {
      final aqi = d['aqi'] as int;
      final score = (100 - (aqi * 0.4)).round().clamp(10, 100);
      return {'day': d['day'], 'score': score};
    }).toList();
  }

  Widget _buildInsightCard(ThemeData theme, List<Map<String, dynamic>> weeklyData) {
    // Generate dynamic insight from data
    final highDays = weeklyData.where((d) => (d['aqi'] as int) > 150).map((d) => d['day']).toList();
    final insight = highDays.isEmpty
        ? 'Air quality has been within acceptable limits this week. Continue normal outdoor activities.'
        : 'Symptoms increase significantly when AQI exceeds safe limits (>150). '
            '${highDays.join(" and ")} showed the highest correlation between poor air quality and symptom severity.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.purple.shade50]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Insight', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(insight, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAqiSymptomsChart(ThemeData theme, List<Map<String, dynamic>> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AQI vs Symptoms', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              _legendDot(Colors.orange, 'AQI (÷20)'),
              const SizedBox(width: 16),
              _legendDot(Colors.red, 'Symptoms'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 12,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                          return Text(data[value.toInt()]['day'] as String, style: const TextStyle(fontSize: 11));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                barGroups: List.generate(data.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: (data[i]['aqi'] as int) / 20,
                        color: Colors.orange,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: (data[i]['symptoms'] as int).toDouble(),
                        color: Colors.red,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreChart(ThemeData theme, List<Map<String, dynamic>> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Health Score', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          _legendDot(Colors.teal, 'Health Score'),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                          return Text(data[value.toInt()]['day'] as String, style: const TextStyle(fontSize: 11));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), (data[i]['score'] as int).toDouble())),
                    isCurved: true,
                    color: Colors.teal,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.teal.withValues(alpha: 0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _statCard(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
