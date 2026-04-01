import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/risk_calculator.dart';
import '../services/data_provider.dart';

class DailyPlanScreen extends StatelessWidget {
  final UserProfile profile;
  final DataProvider dataProvider;
  const DailyPlanScreen({super.key, required this.profile, required this.dataProvider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final env = dataProvider.envData;
    final risk = RiskCalculator.calculate(profile, env);
    final isHighRisk = risk.level == RiskLevel.high;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Plan', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Personalized for ${profile.condition.label} • AQI ${env.aqi}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              if (dataProvider.isRealData) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Live', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildOutdoorTime(theme, isHighRisk)),
              const SizedBox(width: 20),
              Expanded(child: _buildExercise(theme, isHighRisk)),
            ],
          ),

          const SizedBox(height: 20),

          _buildTimeline(theme, isHighRisk),

          const SizedBox(height: 20),

          _buildAlerts(theme, risk),
        ],
      ),
    );
  }

  Widget _buildOutdoorTime(ThemeData theme, bool isHighRisk) {
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
          Row(
            children: [
              Icon(Icons.wb_sunny, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              Text('Safe Outdoor Time', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isHighRisk ? Colors.red.withValues(alpha: 0.05) : Colors.green.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  isHighRisk ? Icons.warning_amber : Icons.check_circle,
                  size: 40,
                  color: isHighRisk ? Colors.red : Colors.green,
                ),
                const SizedBox(height: 8),
                Text(
                  isHighRisk ? 'Avoid Outdoor Activity' : '6:00 AM – 8:00 AM',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isHighRisk ? Colors.red : Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isHighRisk
                      ? 'AQI is too high for outdoor exposure today'
                      : 'Best window for outdoor activities',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _timeSlot(theme, '6:00 – 8:00 AM', 'Good', Colors.green),
          _timeSlot(theme, '8:00 – 11:00 AM', 'Moderate', Colors.orange),
          _timeSlot(theme, '11:00 AM – 4:00 PM', 'Poor', Colors.red),
          _timeSlot(theme, '4:00 – 6:00 PM', 'Moderate', Colors.orange),
          _timeSlot(theme, '6:00 – 8:00 PM', 'Fair', Colors.lightGreen),
        ],
      ),
    );
  }

  Widget _timeSlot(ThemeData theme, String time, String quality, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(time, style: theme.textTheme.bodySmall)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(quality, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildExercise(ThemeData theme, bool isHighRisk) {
    final exercises = isHighRisk
        ? [
            {'name': 'Indoor Yoga', 'duration': '20 min', 'icon': Icons.self_improvement},
            {'name': 'Breathing Exercise', 'duration': '10 min', 'icon': Icons.air},
            {'name': 'Light Stretching', 'duration': '15 min', 'icon': Icons.accessibility_new},
          ]
        : [
            {'name': 'Morning Walk', 'duration': '30 min', 'icon': Icons.directions_walk},
            {'name': 'Light Jogging', 'duration': '15 min', 'icon': Icons.directions_run},
            {'name': 'Breathing Exercise', 'duration': '10 min', 'icon': Icons.air},
          ];

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
          Row(
            children: [
              Icon(Icons.fitness_center, color: Colors.teal.shade600),
              const SizedBox(width: 8),
              Text('Exercise Suggestion', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...exercises.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(e['icon'] as IconData, color: Colors.teal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(e['name'] as String, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(e['duration'] as String, style: TextStyle(fontSize: 12, color: Colors.teal.shade700, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTimeline(ThemeData theme, bool isHighRisk) {
    final items = [
      {'time': '6:00 AM', 'task': 'Morning breathing exercise', 'icon': Icons.air, 'color': Colors.teal},
      {'time': '7:00 AM', 'task': isHighRisk ? 'Indoor light exercise' : 'Outdoor walk (mask recommended)', 'icon': Icons.directions_walk, 'color': Colors.blue},
      {'time': '8:00 AM', 'task': 'Check AQI before leaving home', 'icon': Icons.cloud, 'color': Colors.orange},
      {'time': '12:00 PM', 'task': 'Stay indoors – peak pollution hours', 'icon': Icons.home, 'color': Colors.red},
      {'time': '5:00 PM', 'task': 'Evening stretching / yoga', 'icon': Icons.self_improvement, 'color': Colors.purple},
      {'time': '9:00 PM', 'task': 'Relaxation breathing before sleep', 'icon': Icons.nightlight, 'color': Colors.indigo},
    ];

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
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Text('Daily Timeline', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(item['time'] as String, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item['icon'] as IconData, size: 16, color: item['color'] as Color),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item['task'] as String, style: theme.textTheme.bodyMedium)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAlerts(ThemeData theme, RiskResult risk) {
    final alerts = <Map<String, dynamic>>[];
    if (risk.level == RiskLevel.high) {
      alerts.add({'msg': 'Avoid outdoor activities until AQI improves', 'severity': 'high'});
      alerts.add({'msg': 'Keep rescue inhaler accessible', 'severity': 'high'});
    }
    if (risk.level != RiskLevel.low) {
      alerts.add({'msg': 'Wear N95 mask if going outdoors', 'severity': 'medium'});
      alerts.add({'msg': 'Keep windows closed during peak hours (11AM–4PM)', 'severity': 'medium'});
    }
    alerts.add({'msg': 'Stay hydrated – drink at least 8 glasses of water', 'severity': 'low'});
    alerts.add({'msg': 'Use air purifier indoors if available', 'severity': 'low'});

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
          Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.deepOrange),
              const SizedBox(width: 8),
              Text('Today\'s Alerts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...alerts.map((a) {
            final color = a['severity'] == 'high' ? Colors.red : a['severity'] == 'medium' ? Colors.orange : Colors.blue;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border(left: BorderSide(color: color, width: 3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: color),
                  const SizedBox(width: 10),
                  Expanded(child: Text(a['msg'] as String, style: theme.textTheme.bodyMedium)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
