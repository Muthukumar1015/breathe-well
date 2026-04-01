import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

class _RouteScreenState extends State<RouteScreen> with TickerProviderStateMixin {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  List<RouteOption>? _routes;
  bool _loading = false;
  bool _isRealAqi = false;
  bool _gpsLoading = false;
  String? _gpsError;
  int _selectedRouteIndex = -1;

  // Location data
  double? _fromLat, _fromLon;
  double? _toLat, _toLon;

  // Search suggestions
  List<({String name, double lat, double lon})> _fromSuggestions = [];
  List<({String name, double lat, double lon})> _toSuggestions = [];
  bool _showFromSuggestions = false;
  bool _showToSuggestions = false;
  Timer? _fromDebounce;
  Timer? _toDebounce;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromDebounce?.cancel();
    _toDebounce?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ─── GPS Auto-Detect ───────────────────────────────────────────────
  Future<void> _detectCurrentLocation() async {
    setState(() {
      _gpsLoading = true;
      _gpsError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _gpsError = 'Location services are disabled. Please enable GPS.';
          _gpsLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _gpsError = 'Location permission denied. Please allow access.';
            _gpsLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _gpsError = 'Location permission permanently denied. Enable in settings.';
          _gpsLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _fromLat = position.latitude;
      _fromLon = position.longitude;

      // Reverse geocode to get place name
      final placeName = await ApiService.reverseGeocode(position.latitude, position.longitude);
      setState(() {
        _fromController.text = placeName ?? '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _gpsLoading = false;
      });
    } catch (e) {
      setState(() {
        _gpsError = 'Could not detect location. Try manual input.';
        _gpsLoading = false;
      });
    }
  }

  // ─── Search Autocomplete ──────────────────────────────────────────
  void _onFromSearchChanged(String query) {
    _fromDebounce?.cancel();
    _fromDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.length < 2) {
        setState(() => _fromSuggestions = []);
        return;
      }
      final results = await ApiService.searchLocations(query);
      setState(() {
        _fromSuggestions = results;
        _showFromSuggestions = results.isNotEmpty;
      });
    });
  }

  void _onToSearchChanged(String query) {
    _toDebounce?.cancel();
    _toDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.length < 2) {
        setState(() => _toSuggestions = []);
        return;
      }
      final results = await ApiService.searchLocations(query);
      setState(() {
        _toSuggestions = results;
        _showToSuggestions = results.isNotEmpty;
      });
    });
  }

  void _selectFromSuggestion(({String name, double lat, double lon}) place) {
    setState(() {
      _fromController.text = place.name;
      _fromLat = place.lat;
      _fromLon = place.lon;
      _showFromSuggestions = false;
      _fromSuggestions = [];
    });
  }

  void _selectToSuggestion(({String name, double lat, double lon}) place) {
    setState(() {
      _toController.text = place.name;
      _toLat = place.lat;
      _toLon = place.lon;
      _showToSuggestions = false;
      _toSuggestions = [];
    });
  }

  // ─── Find Routes ──────────────────────────────────────────────────
  Future<void> _findRoutes() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both locations'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _loading = true;
      _selectedRouteIndex = -1;
    });

    // Geocode "from" if not already set
    if (_fromLat == null) {
      final fromGeo = await ApiService.geocodeCity(_fromController.text.split(',').first.trim());
      if (fromGeo != null) {
        _fromLat = fromGeo.lat;
        _fromLon = fromGeo.lon;
      }
    }

    // Geocode "to" if not already set
    if (_toLat == null) {
      final toGeo = await ApiService.geocodeCity(_toController.text.split(',').first.trim());
      if (toGeo != null) {
        _toLat = toGeo.lat;
        _toLon = toGeo.lon;
      }
    }

    // Fetch real AQI for destination
    int? realAqi;
    if (_toLat != null && _toLon != null) {
      final env = await ApiService.fetchAirQuality(_toLat!, _toLon!, _toController.text);
      if (env != null) {
        realAqi = env.aqi;
        _isRealAqi = true;
      }
    }

    // Also fetch AQI for source
    int? sourceAqi;
    if (_fromLat != null && _fromLon != null) {
      final env = await ApiService.fetchAirQuality(_fromLat!, _fromLon!, _fromController.text);
      if (env != null) {
        sourceAqi = env.aqi;
      }
    }

    // Build routes using real AQI data
    final baseRoutes = MockData.getRoutes();
    final baseAqi = realAqi ?? sourceAqi ?? 100;

    if (realAqi != null || sourceAqi != null) {
      // Calculate distance between points for realistic route distances
      double baseDist = 10.0;
      if (_fromLat != null && _toLat != null) {
        baseDist = _calculateDistance(_fromLat!, _fromLon!, _toLat!, _toLon!);
      }

      _routes = [
        RouteOption(
          name: 'Route A – Via Highway',
          aqi: (baseAqi * 1.3).round().clamp(0, 500),
          distanceKm: double.parse((baseDist * 0.9).toStringAsFixed(1)),
          estimatedMinutes: (baseDist * 2.2).round(),
          zones: ['Industrial Zone', 'Traffic Corridor', 'Highway'],
        ),
        RouteOption(
          name: 'Route B – Via Park Road',
          aqi: (baseAqi * 0.55).round().clamp(0, 500),
          distanceKm: double.parse((baseDist * 1.15).toStringAsFixed(1)),
          estimatedMinutes: (baseDist * 2.8).round(),
          zones: ['Residential Area', 'City Park', 'Green Belt'],
          recommended: true,
        ),
        RouteOption(
          name: 'Route C – Via Metro',
          aqi: (baseAqi * 0.85).round().clamp(0, 500),
          distanceKm: double.parse(baseDist.toStringAsFixed(1)),
          estimatedMinutes: (baseDist * 2.5).round(),
          zones: ['Metro Station', 'Commercial District'],
        ),
      ];
    } else {
      _routes = baseRoutes;
      _isRealAqi = false;
    }

    setState(() => _loading = false);
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // km
  }

  Color _aqiColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.lightGreen;
    if (aqi <= 150) return Colors.orange;
    return Colors.red;
  }

  String _aqiLabel(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy (Sensitive)';
    if (aqi <= 200) return 'Unhealthy';
    return 'Hazardous';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ────────────────────────────────────────────
          Row(
            children: [
              Text('Smart Route Navigation',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                      Text('Live AQI Data',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Find the safest route with lowest pollution exposure',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 24),

          // ─── Location Input Section ────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location mode selector
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.teal, size: 20),
                    const SizedBox(width: 8),
                    Text('Set Your Locations',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),

                // FROM location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline dots
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        children: [
                          Container(
                            width: 14, height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                              border: Border.all(color: Colors.blue.shade200, width: 3),
                            ),
                          ),
                          Container(width: 2, height: 50, color: Colors.grey.shade300),
                          Container(
                            width: 14, height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                              border: Border.all(color: Colors.red.shade200, width: 3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Input fields
                    Expanded(
                      child: Column(
                        children: [
                          // FROM field with GPS button
                          _buildLocationField(
                            controller: _fromController,
                            label: 'Current Location',
                            icon: Icons.my_location,
                            iconColor: Colors.blue,
                            suggestions: _fromSuggestions,
                            showSuggestions: _showFromSuggestions,
                            onChanged: _onFromSearchChanged,
                            onSuggestionTap: _selectFromSuggestion,
                            onDismissSuggestions: () => setState(() => _showFromSuggestions = false),
                            trailing: _gpsLoading
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.gps_fixed, color: Colors.blue),
                                    tooltip: 'Auto-detect location (GPS)',
                                    onPressed: _detectCurrentLocation,
                                  ),
                            theme: theme,
                          ),
                          const SizedBox(height: 12),

                          // TO field
                          _buildLocationField(
                            controller: _toController,
                            label: 'Destination',
                            icon: Icons.flag,
                            iconColor: Colors.red,
                            suggestions: _toSuggestions,
                            showSuggestions: _showToSuggestions,
                            onChanged: _onToSearchChanged,
                            onSuggestionTap: _selectToSuggestion,
                            onDismissSuggestions: () => setState(() => _showToSuggestions = false),
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // GPS error message
                if (_gpsError != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_gpsError!,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Find Routes button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _findRoutes,
                    icon: _loading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.route),
                    label: Text(_loading ? 'Analyzing Routes...' : 'Find Safest Routes'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Route Map Visualization ───────────────────────────
          if (_routes != null) ...[
            // Recommendation banner
            () {
              final recommended = _routes!.firstWhere(
                (r) => r.recommended,
                orElse: () => _routes!.reduce((a, b) => a.aqi < b.aqi ? a : b),
              );
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recommended: ${recommended.name}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                          const SizedBox(height: 2),
                          Text('AQI ${recommended.aqi} · Lower pollution · Safer for respiratory health',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }(),
            const SizedBox(height: 20),

            // Visual Map with Routes
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(
                  painter: _RouteMapPainter(
                    routes: _routes!,
                    selectedIndex: _selectedRouteIndex,
                    from: _fromController.text,
                    to: _toController.text,
                  ),
                  child: Stack(
                    children: [
                      // Map legend
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Pollution Legend', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              _legendItem('Safe (AQI 0-50)', Colors.green),
                              _legendItem('Moderate (51-100)', Colors.lightGreen),
                              _legendItem('Unhealthy (101-150)', Colors.orange),
                              _legendItem('Dangerous (150+)', Colors.red),
                            ],
                          ),
                        ),
                      ),
                      // Location labels
                      Positioned(
                        left: 30,
                        top: 125,
                        child: _locationPin(
                          _fromController.text.split(',').first,
                          Colors.blue,
                          Icons.my_location,
                        ),
                      ),
                      Positioned(
                        right: 30,
                        top: 125,
                        child: _locationPin(
                          _toController.text.split(',').first,
                          Colors.red,
                          Icons.flag,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ─── Route Cards ──────────────────────────────────────
            Text('Select a Route',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._routes!.asMap().entries.map((entry) => _buildRouteCard(theme, entry.value, entry.key)),
          ],
        ],
      ),
    );
  }

  // ─── Location Input Field Widget ───────────────────────────────────
  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    required List<({String name, double lat, double lon})> suggestions,
    required bool showSuggestions,
    required Function(String) onChanged,
    required Function(({String name, double lat, double lon})) onSuggestionTap,
    required VoidCallback onDismissSuggestions,
    required ThemeData theme,
    Widget? trailing,
  }) {
    return Column(
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          onTap: () {
            if (suggestions.isNotEmpty) {
              setState(() {});
            }
          },
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Search city, district, or place...',
            prefixIcon: Icon(icon, color: iconColor, size: 20),
            suffixIcon: trailing,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        // Suggestions dropdown
        if (showSuggestions && suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: suggestions.map((place) => InkWell(
                onTap: () => onSuggestionTap(place),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(place.name,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _locationPin(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _legendItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 16, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // ─── Route Card ────────────────────────────────────────────────────
  Widget _buildRouteCard(ThemeData theme, RouteOption route, int index) {
    final color = _aqiColor(route.aqi);
    final isGood = route.recommended;
    final isSelected = _selectedRouteIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedRouteIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.05) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : (isGood ? Colors.green : Colors.grey.shade300),
            width: isSelected ? 2.5 : (isGood ? 2 : 1),
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 16 : 10,
            ),
          ],
        ),
        child: Row(
          children: [
            // AQI circle
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
                  Text('AQI', style: theme.textTheme.bodySmall?.copyWith(color: color, fontSize: 10)),
                  Text('${route.aqi}',
                      style: theme.textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
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
                      Flexible(
                        child: Text(route.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
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
                          decoration: BoxDecoration(
                              color: route.aqi > 150 ? Colors.red.withValues(alpha: 0.8) : Colors.orange.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            route.aqi > 150 ? 'AVOID' : 'CAUTION',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_aqiLabel(route.aqi),
                      style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _infoChip(Icons.straighten, '${route.distanceKm} km', theme),
                      const SizedBox(width: 12),
                      _infoChip(Icons.access_time, '${route.estimatedMinutes} min', theme),
                      const SizedBox(width: 12),
                      // Pollution exposure bar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Exposure', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey)),
                            const SizedBox(height: 2),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (route.aqi / 300).clamp(0.0, 1.0),
                                backgroundColor: Colors.grey.shade200,
                                color: color,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
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

            // Color bar indicator
            Container(
              width: 12,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withValues(alpha: 0.3), color],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
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

// ─── Custom Map Painter ───────────────────────────────────────────────
class _RouteMapPainter extends CustomPainter {
  final List<RouteOption> routes;
  final int selectedIndex;
  final String from;
  final String to;

  _RouteMapPainter({
    required this.routes,
    required this.selectedIndex,
    required this.from,
    required this.to,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background grid
    final gridPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Simulated green areas (parks)
    final parkPaint = Paint()..color = Colors.green.withValues(alpha: 0.12);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.35), width: 120, height: 80), parkPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.45, size.height * 0.7), width: 90, height: 60), parkPaint);

    // Simulated pollution zones
    final pollutionPaint = Paint()..color = Colors.red.withValues(alpha: 0.06);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.35, size.height * 0.25), width: 100, height: 70), pollutionPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.6, size.height * 0.75), width: 110, height: 70), pollutionPaint);

    final startX = 60.0;
    final endX = size.width - 60;
    final midY = size.height / 2;

    // Draw route paths
    for (int i = routes.length - 1; i >= 0; i--) {
      final route = routes[i];
      final isSelected = i == selectedIndex;

      Color routeColor;
      if (route.aqi <= 50) {
        routeColor = Colors.green;
      } else if (route.aqi <= 100) {
        routeColor = Colors.lightGreen;
      } else if (route.aqi <= 150) {
        routeColor = Colors.orange;
      } else {
        routeColor = Colors.red;
      }

      final paint = Paint()
        ..color = isSelected ? routeColor : routeColor.withValues(alpha: 0.5)
        ..strokeWidth = isSelected ? 5 : 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(startX, midY);

      // Different curve for each route
      switch (i) {
        case 0: // Route A - top curve (highway)
          path.cubicTo(
            size.width * 0.3, midY - 90,
            size.width * 0.7, midY - 70,
            endX, midY,
          );
          break;
        case 1: // Route B - middle curve (park road - safest)
          path.cubicTo(
            size.width * 0.35, midY + 30,
            size.width * 0.65, midY - 30,
            endX, midY,
          );
          break;
        case 2: // Route C - bottom curve (metro)
          path.cubicTo(
            size.width * 0.3, midY + 80,
            size.width * 0.7, midY + 60,
            endX, midY,
          );
          break;
      }

      // Draw shadow
      final shadowPaint = Paint()
        ..color = routeColor.withValues(alpha: 0.15)
        ..strokeWidth = (isSelected ? 5 : 3) + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(path, shadowPaint);
      canvas.drawPath(path, paint);

      // Route label
      final labelOffset = switch (i) {
        0 => Offset(size.width * 0.48, midY - 85),
        1 => Offset(size.width * 0.48, midY - 5),
        _ => Offset(size.width * 0.48, midY + 75),
      };

      // Label background
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: labelOffset, width: 60, height: 20),
        const Radius.circular(10),
      );
      canvas.drawRRect(labelRect, Paint()..color = routeColor.withValues(alpha: 0.9));
      canvas.drawRRect(labelRect, Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);

      final textPainter = TextPainter(
        text: TextSpan(
          text: 'AQI ${route.aqi}',
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(labelOffset.dx - textPainter.width / 2, labelOffset.dy - textPainter.height / 2));
    }

    // Start marker
    canvas.drawCircle(Offset(startX, midY), 10, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(startX, midY), 10, Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    canvas.drawCircle(Offset(startX, midY), 4, Paint()..color = Colors.blue);

    // End marker
    canvas.drawCircle(Offset(endX, midY), 10, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(endX, midY), 10, Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    canvas.drawCircle(Offset(endX, midY), 4, Paint()..color = Colors.red);
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter oldDelegate) =>
      selectedIndex != oldDelegate.selectedIndex || routes != oldDelegate.routes;
}
