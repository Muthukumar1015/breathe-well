import 'package:flutter/foundation.dart';
import '../models/environment_data.dart';
import 'api_service.dart';
import 'mock_data.dart';

class DataProvider extends ChangeNotifier {
  EnvironmentData? _envData;
  List<Map<String, dynamic>>? _weeklyData;
  bool _loading = false;
  bool _isRealData = false;
  String? _error;
  double _lat = 19.076; // Mumbai default
  double _lon = 72.8777;
  String _cityName = 'Mumbai, Maharashtra';

  EnvironmentData get envData => _envData ?? MockData.getEnvironmentData();
  List<Map<String, dynamic>> get weeklyData => _weeklyData ?? MockData.getWeeklyData();
  bool get loading => _loading;
  bool get isRealData => _isRealData;
  String? get error => _error;
  String get cityName => _cityName;
  double get lat => _lat;
  double get lon => _lon;

  /// Search city and fetch real AQI data
  Future<void> loadCity(String city) async {
    _loading = true;
    _error = null;
    notifyListeners();

    // Step 1: Geocode city
    final geo = await ApiService.geocodeCity(city);
    if (geo == null) {
      _error = 'City not found. Using cached data.';
      _loading = false;
      notifyListeners();
      return;
    }

    _lat = geo.lat;
    _lon = geo.lon;
    _cityName = geo.name;

    // Step 2: Fetch real AQI
    final env = await ApiService.fetchAirQuality(_lat, _lon, _cityName);
    if (env != null) {
      _envData = env;
      _isRealData = true;
    } else {
      _error = 'API unavailable. Using simulated data.';
      _isRealData = false;
    }

    // Step 3: Fetch weekly history
    final weekly = await ApiService.fetchWeeklyAqi(_lat, _lon);
    if (weekly != null && weekly.isNotEmpty) {
      _weeklyData = weekly;
    }

    _loading = false;
    notifyListeners();
  }

  /// Refresh current location data
  Future<void> refresh() async {
    await loadCity(_cityName.split(',').first.trim());
  }

  /// Load default city on startup
  Future<void> init() async {
    await loadCity('Mumbai');
  }
}
