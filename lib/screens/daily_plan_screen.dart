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

    // Generate route recommendations based on AQI
    final routes = _getRouteRecommendations(env.aqi);

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

          // ─── Safe Time + Route Recommendation Banner ───────────
          _buildSafeTimeRouteBanner(theme, isHighRisk, env.aqi, routes),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildOutdoorTime(theme, isHighRisk)),
              const SizedBox(width: 20),
              Expanded(child: _buildRouteRecommendation(theme, isHighRisk, routes, env.aqi)),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildExercise(theme, isHighRisk)),
              const SizedBox(width: 20),
              Expanded(child: _buildTimeline(theme, isHighRisk)),
            ],
          ),

          const SizedBox(height: 20),

          _buildAlerts(theme, risk),
        ],
      ),
    );
  }

  // ─── Route Recommendations based on AQI ────────────────────────────
  List<_RouteRecommendation> _getRouteRecommendations(int aqi) {
    return [
      _RouteRecommendation(
        name: 'Route A – Via Highway',
        aqi: (aqi * 1.3).round().clamp(0, 500),
        zones: ['Industrial Zone', 'Traffic Corridor'],
        distanceKm: 3.2,
        isSafe: false,
      ),
      _RouteRecommendation(
        name: 'Route B – Via Park Road',
        aqi: (aqi * 0.55).round().clamp(0, 500),
        zones: ['City Park', 'Green Belt', 'Residential'],
        distanceKm: 4.1,
        isSafe: true,
      ),
      _RouteRecommendation(
        name: 'Route C – Via Metro Road',
        aqi: (aqi * 0.85).round().clamp(0, 500),
        zones: ['Metro Station', 'Commercial Area'],
        distanceKm: 3.5,
        isSafe: false,
      ),
    ];
  }

  // ─── Combined Banner: Safe Time + Best Route ───────────────────────
  Widget _buildSafeTimeRouteBanner(ThemeData theme, bool isHighRisk, int aqi, List<_RouteRecommendation> routes) {
    final bestRoute = routes.firstWhere((r) => r.isSafe, orElse: () => routes.reduce((a, b) => a.aqi < b.aqi ? a : b));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isHighRisk
              ? [Colors.red.shade50, Colors.orange.shade50]
              : [Colors.green.shade50, Colors.teal.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isHighRisk ? Colors.red.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          // Safe Time
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isHighRisk ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isHighRisk ? Icons.warning_amber : Icons.schedule,
                    color: isHighRisk ? Colors.red : Colors.green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Safe Time',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: isHighRisk ? Colors.red.shade700 : Colors.green.shade700,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        isHighRisk ? 'Avoid Outdoor' : '6:00 AM – 8:00 AM',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isHighRisk ? Colors.red.shade800 : Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 60,
            color: (isHighRisk ? Colors.red : Colors.green).withValues(alpha: 0.2),
          ),
          const SizedBox(width: 16),

          // Best Route
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.route, color: Colors.teal, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Safest Route',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.teal.shade700, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        bestRoute.name.replaceAll('Route B – ', ''),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                      ),
                      Text('AQI ${bestRoute.aqi}',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Safe Outdoor Time ─────────────────────────────────────────────
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

  // ─── Route Recommendation for Outdoor Activities ────────────────────
  Widget _buildRouteRecommendation(ThemeData theme, bool isHighRisk, List<_RouteRecommendation> routes, int aqi) {
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
              Icon(Icons.route, color: Colors.teal.shade600),
              const SizedBox(width: 8),
              Text('Route Safety for Activities', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Recommended paths for walking & jogging',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 16),

          // Route comparison cards
          ...routes.map((route) {
            final color = route.isSafe ? Colors.green : (route.aqi > 150 ? Colors.red : Colors.orange);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: route.isSafe ? Colors.green.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.15),
                  width: route.isSafe ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // AQI badge
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.15),
                          border: Border.all(color: color, width: 2),
                        ),
                        child: Center(
                          child: Text('${route.aqi}',
                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(route.name,
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    route.isSafe ? 'SAFE' : (route.aqi > 150 ? 'AVOID' : 'CAUTION'),
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${route.distanceKm} km • ${route.zones.join(', ')}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11)),
                          ],
                        ),
                      ),
                      // Status icon
                      Icon(
                        route.isSafe ? Icons.check_circle : Icons.cancel,
                        color: route.isSafe ? Colors.green : Colors.red.withValues(alpha: 0.5),
                        size: 22,
                      ),
                    ],
                  ),
                  // Pollution exposure bar
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Pollution:', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (route.aqi / 300).clamp(0.0, 1.0),
                            backgroundColor: Colors.grey.shade200,
                            color: color,
                            minHeight: 5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          // Recommendation message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.teal, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isHighRisk
                        ? 'All routes have high pollution. Stay indoors and do breathing exercises instead.'
                        : 'Route B (Via Park Road) is safest for your morning walk. Lower AQI through green areas.',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.teal.shade700, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Exercise Suggestions ──────────────────────────────────────────
  Widget _buildExercise(ThemeData theme, bool isHighRisk) {
    final exercises = isHighRisk
        ? [
            {'name': 'Indoor Yoga', 'duration': '20 min', 'icon': Icons.self_improvement, 'route': 'Indoors'},
            {'name': 'Breathing Exercise', 'duration': '10 min', 'icon': Icons.air, 'route': 'Indoors'},
            {'name': 'Light Stretching', 'duration': '15 min', 'icon': Icons.accessibility_new, 'route': 'Indoors'},
          ]
        : [
            {'name': 'Morning Walk', 'duration': '30 min', 'icon': Icons.directions_walk, 'route': 'Via Park Road'},
            {'name': 'Light Jogging', 'duration': '15 min', 'icon': Icons.directions_run, 'route': 'Via Park Road'},
            {'name': 'Breathing Exercise', 'duration': '10 min', 'icon': Icons.air, 'route': 'Indoors'},
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
              Text('Exercise + Route Suggestion', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...exercises.map((e) {
            final isOutdoor = (e['route'] as String) != 'Indoors';
            return Container(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['name'] as String, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        if (isOutdoor)
                          Row(
                            children: [
                              Icon(Icons.route, size: 12, color: Colors.green.shade600),
                              const SizedBox(width: 4),
                              Text(e['route'] as String,
                                  style: TextStyle(fontSize: 11, color: Colors.green.shade600, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Low AQI', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                        else
                          Text(e['route'] as String,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(e['duration'] as String,
                        style: TextStyle(fontSize: 12, color: Colors.teal.shade700, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Daily Timeline ────────────────────────────────────────────────
  Widget _buildTimeline(ThemeData theme, bool isHighRisk) {
    final items = [
      {'time': '6:00 AM', 'task': 'Morning breathing exercise', 'icon': Icons.air, 'color': Colors.teal},
      {
        'time': '7:00 AM',
        'task': isHighRisk ? 'Indoor light exercise' : 'Outdoor walk via Park Road (safest)',
        'icon': Icons.directions_walk,
        'color': Colors.blue,
      },
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
                  child: Text(item['time'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
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

  // ─── Alerts ────────────────────────────────────────────────────────
  Widget _buildAlerts(ThemeData theme, RiskResult risk) {
    final alerts = <Map<String, dynamic>>[];
    if (risk.level == RiskLevel.high) {
      alerts.add({'msg': 'Avoid outdoor activities until AQI improves', 'severity': 'high'});
      alerts.add({'msg': 'Keep rescue inhaler accessible', 'severity': 'high'});
      alerts.add({'msg': 'All routes show high pollution – stay indoors', 'severity': 'high'});
    }
    if (risk.level != RiskLevel.low) {
      alerts.add({'msg': 'Wear N95 mask if going outdoors', 'severity': 'medium'});
      alerts.add({'msg': 'Keep windows closed during peak hours (11AM–4PM)', 'severity': 'medium'});
      alerts.add({'msg': 'Use Park Road route if outdoor activity is necessary', 'severity': 'medium'});
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

// ─── Route Recommendation Model ──────────────────────────────────────
class _RouteRecommendation {
  final String name;
  final int aqi;
  final List<String> zones;
  final double distanceKm;
  final bool isSafe;

  _RouteRecommendation({
    required this.name,
    required this.aqi,
    required this.zones,
    required this.distanceKm,
    required this.isSafe,
  });
}
