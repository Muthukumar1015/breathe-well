import 'package:flutter/material.dart';
import '../models/environment_data.dart';

class AqiCard extends StatelessWidget {
  final EnvironmentData data;
  const AqiCard({super.key, required this.data});

  Color _aqiColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.lightGreen;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    return Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _aqiColor(data.aqi);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud, color: color, size: 22),
              const SizedBox(width: 8),
              Text('Environmental Data', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Big AQI number
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text('AQI', style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
                    Text(
                      '${data.aqi}',
                      style: theme.textTheme.displaySmall?.copyWith(color: color, fontWeight: FontWeight.bold),
                    ),
                    Text(data.aqiCategory, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _envItem(theme, Icons.grass, 'Pollen Count', '${data.pollenCount}'),
                    const SizedBox(height: 10),
                    _envItem(theme, Icons.location_on, 'Location', data.location),
                    const SizedBox(height: 10),
                    _envItem(theme, Icons.science, 'Pollutant', data.dominantPollutant),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _envItem(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 6),
        Text('$label: ', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
        Expanded(child: Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
      ],
    );
  }
}
