import '../models/environment_data.dart';

class MockData {
  static EnvironmentData getEnvironmentData() {
    return EnvironmentData(
      aqi: 156,
      pollenCount: 45,
      location: 'Mumbai, Maharashtra',
      aqiCategory: 'Unhealthy',
      dominantPollutant: 'PM2.5',
    );
  }

  static List<RouteOption> getRoutes() {
    return [
      RouteOption(
        name: 'Route A – Via Highway',
        aqi: 180,
        distanceKm: 8.2,
        estimatedMinutes: 22,
        zones: ['Industrial Zone', 'Traffic Corridor', 'Highway'],
      ),
      RouteOption(
        name: 'Route B – Via Park Road',
        aqi: 90,
        distanceKm: 10.5,
        estimatedMinutes: 28,
        zones: ['Residential Area', 'City Park', 'Green Belt'],
        recommended: true,
      ),
      RouteOption(
        name: 'Route C – Via Metro',
        aqi: 120,
        distanceKm: 9.0,
        estimatedMinutes: 25,
        zones: ['Metro Station', 'Commercial District'],
      ),
    ];
  }

  static List<Map<String, dynamic>> getWeeklyData() {
    return [
      {'day': 'Mon', 'aqi': 120, 'symptoms': 3},
      {'day': 'Tue', 'aqi': 95, 'symptoms': 2},
      {'day': 'Wed', 'aqi': 180, 'symptoms': 7},
      {'day': 'Thu', 'aqi': 200, 'symptoms': 8},
      {'day': 'Fri', 'aqi': 150, 'symptoms': 5},
      {'day': 'Sat', 'aqi': 80, 'symptoms': 1},
      {'day': 'Sun', 'aqi': 70, 'symptoms': 1},
    ];
  }

  static List<Map<String, dynamic>> getHealthScores() {
    return [
      {'day': 'Mon', 'score': 72},
      {'day': 'Tue', 'score': 78},
      {'day': 'Wed', 'score': 55},
      {'day': 'Thu', 'score': 48},
      {'day': 'Fri', 'score': 62},
      {'day': 'Sat', 'score': 85},
      {'day': 'Sun', 'score': 88},
    ];
  }
}
