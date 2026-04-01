class EnvironmentData {
  final int aqi;
  final int pollenCount;
  final String location;
  final String aqiCategory;
  final String dominantPollutant;

  EnvironmentData({
    required this.aqi,
    required this.pollenCount,
    required this.location,
    required this.aqiCategory,
    required this.dominantPollutant,
  });
}

class RouteOption {
  final String name;
  final int aqi;
  final double distanceKm;
  final int estimatedMinutes;
  final List<String> zones;
  final bool recommended;

  RouteOption({
    required this.name,
    required this.aqi,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.zones,
    this.recommended = false,
  });
}
