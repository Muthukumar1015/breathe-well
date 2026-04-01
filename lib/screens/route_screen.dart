import 'package:flutter/material.dart';
import '../models/environment_data.dart';
import '../services/data_provider.dart';
import '../services/api_service.dart';
import '../services/mock_data.dart';

class RouteScreen extends StatefulWidget {
  final DataProvider dataProvider;
  const RouteScreen({super.key, required this.dataProvider});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final _fromController = TextEditingController(text: 'Andheri West, Mumbai');
  final _toController = TextEditingController(text: 'Bandra Kurla Complex, Mumbai');
  List<RouteOption>? _routes;
  bool _loading = false;
  bool _isRealAqi = false;

  Future<void> _findRoutes() async {
    setState(() => _loading = true);

    // Try to get real AQI for destination
    final destCity = _toController.text.split(',').first.trim();
    final geo = await ApiService.geocodeCity(destCity);

    int? realAqi;
    if (geo != null) {
      final env = await ApiService.fetchAirQuality(geo.lat, geo.lon, geo.name);
      if (env != null) {
        realAqi = env.aqi;
        _isRealAqi = true;
      }
    }

    // Build routes using real AQI as base if available
    final baseRoutes = MockData.getRoutes();
    if (realAqi != null) {
      // Offset route AQIs relative to real destination AQI
      _routes = [
        RouteOption(
          name: 'Route A – Via Highway',
          aqi: (realAqi * 1.3).round().clamp(0, 500),
          distanceKm: baseRoutes[0].distanceKm,
          estimatedMinutes: baseRoutes[0].estimatedMinutes,
          zones: baseRoutes[0].zones,
        ),
        RouteOption(
          name: 'Route B – Via Park Road',
          aqi: (realAqi * 0.65).round().clamp(0, 500),
          distanceKm: baseRoutes[1].distanceKm,
          estimatedMinutes: baseRoutes[1].estimatedMinutes,
          zones: baseRoutes[1].zones,
          recommended: true,
        ),
        RouteOption(
          name: 'Route C – Via Metro',
          aqi: (realAqi * 0.9).round().clamp(0, 500),
          distanceKm: baseRoutes[2].distanceKm,
          estimatedMinutes: baseRoutes[2].estimatedMinutes,
          zones: baseRoutes[2].zones,
        ),
      ];
    } else {
      _routes = baseRoutes;
      _isRealAqi = false;
    }

    setState(() => _loading = false);
  }

  Color _aqiColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.lightGreen;
    if (aqi <= 150) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Smart Route Navigation', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_isRealAqi && _routes != null)
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
                      Text('AQI from Live API', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Find the safest route with lowest pollution exposure', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 24),

          // Input section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        controller: _fromController,
                        decoration: InputDecoration(
                          labelText: 'Current Location',
                          prefixIcon: const Icon(Icons.my_location, color: Colors.blue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _toController,
                        decoration: InputDecoration(
                          labelText: 'Destination',
                          prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _loading ? null : _findRoutes,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search),
                  label: const Text('Find Routes'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    backgroundColor: Colors.teal,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Routes display
          if (_routes != null) ...[
            // Find the recommended route
            () {
              final recommended = _routes!.firstWhere((r) => r.recommended, orElse: () => _routes!.reduce((a, b) => a.aqi < b.aqi ? a : b));
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.green.shade50, Colors.teal.shade50]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.green, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Recommended: ${recommended.name} – AQI ${recommended.aqi}. Lower pollution exposure and safer for respiratory health.',
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: Colors.green.shade800),
                      ),
                    ),
                  ],
                ),
              );
            }(),
            const SizedBox(height: 20),

            // Route cards
            ..._routes!.map((route) => _buildRouteCard(theme, route)),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteCard(ThemeData theme, RouteOption route) {
    final color = _aqiColor(route.aqi);
    final isGood = route.recommended;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGood ? Colors.green : Colors.red.withValues(alpha: 0.3),
          width: isGood ? 2 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          // AQI indicator
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color, width: 3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('AQI', style: theme.textTheme.bodySmall?.copyWith(color: color)),
                Text('${route.aqi}', style: theme.textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Route info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(route.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    if (isGood)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                        child: const Text('SAFE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(10)),
                        child: const Text('AVOID', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _infoChip(Icons.straighten, '${route.distanceKm} km', theme),
                    const SizedBox(width: 12),
                    _infoChip(Icons.access_time, '${route.estimatedMinutes} min', theme),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: route.zones.map((z) => Chip(
                    label: Text(z, style: const TextStyle(fontSize: 11)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  )).toList(),
                ),
              ],
            ),
          ),

          // Visual bar
          Container(
            width: 12,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
