import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/environment_data.dart';

class ApiService {
  /// Geocode a city name to lat/lon using Open-Meteo Geocoding API (FREE, no key)
  static Future<({double lat, double lon, String name})?> geocodeCity(String city) async {
    final uri = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(city)}&count=1&language=en&format=json',
    );
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final r = results[0];
          return (
            lat: (r['latitude'] as num).toDouble(),
            lon: (r['longitude'] as num).toDouble(),
            name: '${r['name']}, ${r['admin1'] ?? r['country']}',
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetch real AQI + Pollen data from Open-Meteo Air Quality API (FREE, no key)
  static Future<EnvironmentData?> fetchAirQuality(double lat, double lon, String locationName) async {
    final uri = Uri.parse(
      'https://air-quality-api.open-meteo.com/v1/air-quality'
      '?latitude=$lat&longitude=$lon'
      '&current=us_aqi,pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,ozone,dust,alder_pollen,birch_pollen,grass_pollen'
      '&timezone=auto',
    );
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'];
        if (current == null) return null;

        final aqi = (current['us_aqi'] as num?)?.toInt() ?? 0;
        final pm25 = (current['pm2_5'] as num?)?.toDouble() ?? 0;
        final pm10 = (current['pm10'] as num?)?.toDouble() ?? 0;
        final no2 = (current['nitrogen_dioxide'] as num?)?.toDouble() ?? 0;
        final o3 = (current['ozone'] as num?)?.toDouble() ?? 0;

        // Pollen: sum of available pollen types
        final alderPollen = (current['alder_pollen'] as num?)?.toDouble() ?? 0;
        final birchPollen = (current['birch_pollen'] as num?)?.toDouble() ?? 0;
        final grassPollen = (current['grass_pollen'] as num?)?.toDouble() ?? 0;
        final totalPollen = (alderPollen + birchPollen + grassPollen).toInt();

        // Determine dominant pollutant
        final pollutants = {
          'PM2.5': pm25,
          'PM10': pm10,
          'NO₂': no2,
          'O₃': o3,
        };
        final dominant = pollutants.entries.reduce((a, b) => a.value > b.value ? a : b).key;

        // AQI category
        String category;
        if (aqi <= 50) {
          category = 'Good';
        } else if (aqi <= 100) {
          category = 'Moderate';
        } else if (aqi <= 150) {
          category = 'Unhealthy (Sensitive)';
        } else if (aqi <= 200) {
          category = 'Unhealthy';
        } else if (aqi <= 300) {
          category = 'Very Unhealthy';
        } else {
          category = 'Hazardous';
        }

        return EnvironmentData(
          aqi: aqi,
          pollenCount: totalPollen,
          location: locationName,
          aqiCategory: category,
          dominantPollutant: dominant,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Fetch 7-day hourly AQI history for analytics (FREE, no key)
  static Future<List<Map<String, dynamic>>?> fetchWeeklyAqi(double lat, double lon) async {
    final uri = Uri.parse(
      'https://air-quality-api.open-meteo.com/v1/air-quality'
      '?latitude=$lat&longitude=$lon'
      '&hourly=us_aqi'
      '&past_days=7'
      '&timezone=auto',
    );
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hourly = data['hourly'];
        if (hourly == null) return null;

        final times = (hourly['time'] as List).cast<String>();
        final aqiValues = (hourly['us_aqi'] as List);

        // Group by day, get daily average AQI
        final Map<String, List<int>> dailyAqi = {};
        for (int i = 0; i < times.length; i++) {
          final day = times[i].substring(0, 10); // YYYY-MM-DD
          final val = (aqiValues[i] as num?)?.toInt();
          if (val != null) {
            dailyAqi.putIfAbsent(day, () => []).add(val);
          }
        }

        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final result = <Map<String, dynamic>>[];
        int dayIndex = 0;
        for (final entry in dailyAqi.entries) {
          if (dayIndex >= 7) break;
          final avg = entry.value.reduce((a, b) => a + b) ~/ entry.value.length;
          // Simulate symptom correlation: higher AQI = more symptoms
          final symptoms = ((avg / 30).clamp(0, 10)).toInt();
          result.add({
            'day': days[dayIndex % 7],
            'aqi': avg,
            'symptoms': symptoms,
            'date': entry.key,
          });
          dayIndex++;
        }
        return result;
      }
    } catch (_) {}
    return null;
  }
}
