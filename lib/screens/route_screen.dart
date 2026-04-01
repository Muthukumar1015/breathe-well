import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
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

  double? _fromLat, _fromLon;
  double? _toLat, _toLon;

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
    // Auto-detect GPS location on load
    _detectCurrentLocation();
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

  Future<void> _detectCurrentLocation() async {
    setState(() {
      _gpsLoading = true;
      _gpsError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _gpsError = 'Location services are disabled.';
          _gpsLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _gpsError = 'Location permission denied.';
            _gpsLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _gpsError = 'Location permanently denied.';
          _gpsLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _fromLat = position.latitude;
      _fromLon = position.longitude;

      final placeName = await ApiService.reverseGeocode(position.latitude, position.longitude);
      setState(() {
        _fromController.text = placeName ?? '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _gpsLoading = false;
      });
    } catch (e) {
      setState(() {
        _gpsError = 'Could not detect location.';
        _gpsLoading = false;
      });
    }
  }

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

    if (_fromLat == null) {
      final fromGeo = await ApiService.geocodeCity(_fromController.text.split(',').first.trim());
      if (fromGeo != null) {
        _fromLat = fromGeo.lat;
        _fromLon = fromGeo.lon;
      }
    }

    if (_toLat == null) {
      final toGeo = await ApiService.geocodeCity(_toController.text.split(',').first.trim());
      if (toGeo != null) {
        _toLat = toGeo.lat;
        _toLon = toGeo.lon;
      }
    }

    int? realAqi;
    if (_toLat != null && _toLon != null) {
      final env = await ApiService.fetchAirQuality(_toLat!, _toLon!, _toController.text);
      if (env != null) {
        realAqi = env.aqi;
        _isRealAqi = true;
      }
    }

    int? sourceAqi;
    if (_fromLat != null && _fromLon != null) {
      final env = await ApiService.fetchAirQuality(_fromLat!, _fromLon!, _fromController.text);
      if (env != null) {
        sourceAqi = env.aqi;
      }
    }

    final baseRoutes = MockData.getRoutes();
    final baseAqi = realAqi ?? sourceAqi ?? 100;

    if (realAqi != null || sourceAqi != null) {
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
    return 12742 * asin(sqrt(a));
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
    final isMobile = MediaQuery.of(context).size.width < 768;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text('Smart Route Navigation', style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 20 : null,
                )),
              ),
              if (_isRealAqi && _routes != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      Text('Live AQI', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Find the safest route with lowest pollution exposure',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          SizedBox(height: isMobile ? 16 : 24),

          // Location Input
          Container(
            padding: EdgeInsets.all(isMobile ? 14 : 20),
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
                    const Icon(Icons.location_on, color: Colors.teal, size: 20),
                    const SizedBox(width: 8),
                    Text('Set Your Locations', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),

                // FROM field
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
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: const Icon(Icons.gps_fixed, color: Colors.blue),
                          tooltip: 'Auto-detect GPS',
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
                        Expanded(child: Text(_gpsError!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.red))),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _findRoutes,
                    icon: _loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.route),
                    label: Text(_loading ? 'Analyzing...' : 'Find Safest Routes'),
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

          SizedBox(height: isMobile ? 16 : 24),

          // Results
          if (_routes != null) ...[
            // Recommendation banner
            () {
              final recommended = _routes!.firstWhere(
                (r) => r.recommended,
                orElse: () => _routes!.reduce((a, b) => a.aqi < b.aqi ? a : b),
              );
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.green.shade50, Colors.teal.shade50]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recommended: ${recommended.name}',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                          Text('AQI ${recommended.aqi} · Safer for respiratory health',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }(),
            const SizedBox(height: 16),

            // Map visualization (hide on very small screens)
            if (!isMobile || MediaQuery.of(context).size.width > 400)
              Container(
                width: double.infinity,
                height: isMobile ? 200 : 280,
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
                        // Legend (compact on mobile)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: EdgeInsets.all(isMobile ? 6 : 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _legendItem('Safe (0-50)', Colors.green),
                                _legendItem('Moderate', Colors.lightGreen),
                                _legendItem('Unhealthy', Colors.orange),
                                _legendItem('Dangerous', Colors.red),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: isMobile ? 10 : 30,
                          top: isMobile ? 85 : 125,
                          child: _locationPin(_fromController.text.split(',').first, Colors.blue, Icons.my_location),
                        ),
                        Positioned(
                          right: isMobile ? 10 : 30,
                          top: isMobile ? 85 : 125,
                          child: _locationPin(_toController.text.split(',').first, Colors.red, Icons.flag),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            Text('Select a Route', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._routes!.asMap().entries.map((entry) => _buildRouteCard(theme, entry.value, entry.key, isMobile)),
          ],
        ],
      ),
    );
  }

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
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Search city or place...',
            prefixIcon: Icon(icon, color: iconColor, size: 20),
            suffixIcon: trailing,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
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
                      Expanded(child: Text(place.name, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _legendItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 14, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildRouteCard(ThemeData theme, RouteOption route, int index, bool isMobile) {
    final color = _aqiColor(route.aqi);
    final isGood = route.recommended;
    final isSelected = _selectedRouteIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedRouteIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.05) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : (isGood ? Colors.green : Colors.grey.shade300),
            width: isSelected ? 2.5 : (isGood ? 2 : 1),
          ),
          boxShadow: [BoxShadow(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05),
            blurRadius: isSelected ? 16 : 10,
          )],
        ),
        child: Row(
          children: [
            // AQI circle
            Container(
              width: isMobile ? 56 : 80,
              height: isMobile ? 56 : 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color, width: 3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('AQI', style: TextStyle(color: color, fontSize: isMobile ? 9 : 10)),
                  Text('${route.aqi}', style: TextStyle(
                    color: color, fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 22,
                  )),
                ],
              ),
            ),
            SizedBox(width: isMobile ? 12 : 20),

            // Route info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(
                        isMobile ? route.name.replaceAll(' – ', '\n') : route.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 13 : null,
                        ),
                      )),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isGood ? Colors.green : (route.aqi > 150 ? Colors.red.withValues(alpha: 0.8) : Colors.orange.withValues(alpha: 0.8)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isGood ? 'SAFE' : (route.aqi > 150 ? 'AVOID' : 'CAUTION'),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_aqiLabel(route.aqi), style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _infoChip(Icons.straighten, '${route.distanceKm} km', theme),
                      const SizedBox(width: 10),
                      _infoChip(Icons.access_time, '${route.estimatedMinutes} min', theme),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Exposure bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (route.aqi / 300).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade200,
                      color: color,
                      minHeight: 5,
                    ),
                  ),
                  if (!isMobile) ...[
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
                  // Navigate in Google Maps button
                  if (isSelected && _fromLat != null && _toLat != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openInGoogleMaps(),
                        icon: const Icon(Icons.navigation, size: 18),
                        label: const Text('Open in Google Maps'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInGoogleMaps() async {
    if (_fromLat == null || _toLat == null) return;
    final url = 'https://www.google.com/maps/dir/$_fromLat,$_fromLon/$_toLat,$_toLon';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Widget _infoChip(IconData icon, String text, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 3),
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

// ─── Route Map Painter ───────────────────────────────────────────────
class _RouteMapPainter extends CustomPainter {
  final List<RouteOption> routes;
  final int selectedIndex;
  final String from;
  final String to;

  _RouteMapPainter({required this.routes, required this.selectedIndex, required this.from, required this.to});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    final parkPaint = Paint()..color = Colors.green.withValues(alpha: 0.12);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.35), width: 120, height: 80), parkPaint);

    final pollutionPaint = Paint()..color = Colors.red.withValues(alpha: 0.06);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.35, size.height * 0.25), width: 100, height: 70), pollutionPaint);

    final startX = 50.0;
    final endX = size.width - 50;
    final midY = size.height / 2;

    for (int i = routes.length - 1; i >= 0; i--) {
      final route = routes[i];
      final isSelected = i == selectedIndex;

      Color routeColor;
      if (route.aqi <= 50) routeColor = Colors.green;
      else if (route.aqi <= 100) routeColor = Colors.lightGreen;
      else if (route.aqi <= 150) routeColor = Colors.orange;
      else routeColor = Colors.red;

      final paint = Paint()
        ..color = isSelected ? routeColor : routeColor.withValues(alpha: 0.5)
        ..strokeWidth = isSelected ? 5 : 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(startX, midY);

      final curveHeight = size.height * 0.35;
      switch (i) {
        case 0:
          path.cubicTo(size.width * 0.3, midY - curveHeight, size.width * 0.7, midY - curveHeight * 0.8, endX, midY);
          break;
        case 1:
          path.cubicTo(size.width * 0.35, midY + 20, size.width * 0.65, midY - 20, endX, midY);
          break;
        case 2:
          path.cubicTo(size.width * 0.3, midY + curveHeight, size.width * 0.7, midY + curveHeight * 0.7, endX, midY);
          break;
      }

      final shadowPaint = Paint()
        ..color = routeColor.withValues(alpha: 0.15)
        ..strokeWidth = (isSelected ? 5 : 3) + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(path, shadowPaint);
      canvas.drawPath(path, paint);

      final labelOffset = switch (i) {
        0 => Offset(size.width * 0.48, midY - curveHeight * 0.9),
        1 => Offset(size.width * 0.48, midY - 5),
        _ => Offset(size.width * 0.48, midY + curveHeight * 0.8),
      };

      final labelRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: labelOffset, width: 56, height: 18),
        const Radius.circular(9),
      );
      canvas.drawRRect(labelRect, Paint()..color = routeColor.withValues(alpha: 0.9));

      final textPainter = TextPainter(
        text: TextSpan(
          text: 'AQI ${route.aqi}',
          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(labelOffset.dx - textPainter.width / 2, labelOffset.dy - textPainter.height / 2));
    }

    // Start/end markers
    canvas.drawCircle(Offset(startX, midY), 8, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(startX, midY), 8, Paint()..color = Colors.blue..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawCircle(Offset(startX, midY), 3, Paint()..color = Colors.blue);

    canvas.drawCircle(Offset(endX, midY), 8, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(endX, midY), 8, Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawCircle(Offset(endX, midY), 3, Paint()..color = Colors.red);
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter oldDelegate) =>
      selectedIndex != oldDelegate.selectedIndex || routes != oldDelegate.routes;
}
