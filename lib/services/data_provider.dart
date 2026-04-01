import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
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
  DateTime? _lastUpdated;
  Timer? _refreshTimer;
  bool _gpsDetected = false;

  EnvironmentData get envData => _envData ?? MockData.getEnvironmentData();
  List<Map<String, dynamic>> get weeklyData => _weeklyData ?? MockData.getWeeklyData();
  bool get loading => _loading;
  bool get isRealData => _isRealData;
  String? get error => _error;
  String get cityName => _cityName;
  double get lat => _lat;
  double get lon => _lon;
  DateTime? get lastUpdated => _lastUpdated;
  bool get gpsDetected => _gpsDetected;

  /// Initialize: try GPS first, fallback to default city
  Future<void> init() async {
    final gpsSuccess = await _detectGpsLocation();
    if (!gpsSuccess) {
      // Fallback to default location
      await _fetchDataForCoords(_lat, _lon, _cityName);
    }
    // Start auto-refresh every 10 minutes
    _startAutoRefresh();
  }

  /// Detect GPS location and fetch data for it
  Future<bool> _detectGpsLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services disabled. Enable GPS for accurate data.';
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permission denied. Using default location.';
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permission permanently denied. Go to settings to enable.';
        notifyListeners();
        return false;
      }

      _loading = true;
      notifyListeners();

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _lat = position.latitude;
      _lon = position.longitude;
      _gpsDetected = true;

      // Reverse geocode to get city name
      final placeName = await ApiService.reverseGeocode(_lat, _lon);
      _cityName = placeName ?? '${_lat.toStringAsFixed(2)}, ${_lon.toStringAsFixed(2)}';

      // Fetch environmental data for GPS coordinates
      await _fetchDataForCoords(_lat, _lon, _cityName);
      return true;
    } catch (e) {
      _error = 'GPS detection failed. Using default location.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch AQI + weekly data for specific coordinates
  Future<void> _fetchDataForCoords(double lat, double lon, String locationName) async {
    _loading = true;
    _error = null;
    notifyListeners();

    // Fetch real-time AQI
    final env = await ApiService.fetchAirQuality(lat, lon, locationName);
    if (env != null) {
      _envData = env;
      _isRealData = true;
      _lastUpdated = DateTime.now();
    } else {
      _error = 'Unable to retrieve environmental data. Showing cached values.';
      _isRealData = false;
    }

    // Fetch weekly history
    final weekly = await ApiService.fetchWeeklyAqi(lat, lon);
    if (weekly != null && weekly.isNotEmpty) {
      _weeklyData = weekly;
    }

    _loading = false;
    notifyListeners();
  }

  /// Search city and fetch real AQI data (when user changes location)
  Future<void> loadCity(String city) async {
    _loading = true;
    _error = null;
    notifyListeners();

    // Geocode city
    final geo = await ApiService.geocodeCity(city);
    if (geo == null) {
      _error = 'City "$city" not found. Keeping current data.';
      _loading = false;
      notifyListeners();
      return;
    }

    _lat = geo.lat;
    _lon = geo.lon;
    _cityName = geo.name;
    _gpsDetected = false; // User manually changed location

    await _fetchDataForCoords(_lat, _lon, _cityName);
  }

  /// Load data by coordinates directly (from GPS)
  Future<void> loadCoords(double lat, double lon) async {
    _lat = lat;
    _lon = lon;
    _gpsDetected = true;

    final placeName = await ApiService.reverseGeocode(lat, lon);
    _cityName = placeName ?? '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';

    await _fetchDataForCoords(lat, lon, _cityName);
  }

  /// Refresh current location data
  Future<void> refresh() async {
    if (_gpsDetected) {
      // Re-detect GPS for latest position
      final success = await _detectGpsLocation();
      if (!success) {
        await _fetchDataForCoords(_lat, _lon, _cityName);
      }
    } else {
      await _fetchDataForCoords(_lat, _lon, _cityName);
    }
  }

  /// Auto-refresh every 10 minutes
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      refresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
