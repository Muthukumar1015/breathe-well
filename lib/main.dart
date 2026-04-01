import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/user_profile.dart';
import 'services/data_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/breathing_screen.dart';
import 'screens/route_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/daily_plan_screen.dart';

void main() {
  runApp(const BreatheWellApp());
}

class BreatheWellApp extends StatelessWidget {
  const BreatheWellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Breathe Well',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

const _navItems = [
  _NavItem(Icons.dashboard, 'Dashboard'),
  _NavItem(Icons.air, 'Breathing'),
  _NavItem(Icons.route, 'Routes'),
  _NavItem(Icons.analytics, 'Analytics'),
  _NavItem(Icons.emergency, 'Emergency'),
  _NavItem(Icons.calendar_today, 'Daily Plan'),
];

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final _profile = UserProfile(name: 'Rahul Sharma', age: 28, location: 'Mumbai, India', condition: HealthCondition.asthma);
  final _dataProvider = DataProvider();

  @override
  void initState() {
    super.initState();
    _dataProvider.addListener(_onDataChanged);
    _dataProvider.init();
  }

  @override
  void dispose() {
    _dataProvider.removeListener(_onDataChanged);
    _dataProvider.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {});
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _profile.name);
    final ageCtrl = TextEditingController(text: '${_profile.age}');
    final locationCtrl = TextEditingController(text: _profile.location);
    var selectedCondition = _profile.condition;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                    labelText: 'Location (city name)',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<HealthCondition>(
                  initialValue: selectedCondition,
                  decoration: InputDecoration(
                    labelText: 'Health Condition',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: HealthCondition.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedCondition = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final newLocation = locationCtrl.text;
                setState(() {
                  _profile.name = nameCtrl.text;
                  _profile.age = int.tryParse(ageCtrl.text) ?? _profile.age;
                  _profile.location = newLocation;
                  _profile.condition = selectedCondition;
                });
                // Fetch real data for new city
                _dataProvider.loadCity(newLocation.split(',').first.trim());
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreen() {
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(
          profile: _profile,
          onEditProfile: _showEditProfileDialog,
          dataProvider: _dataProvider,
        );
      case 1:
        return BreathingScreen(profile: _profile);
      case 2:
        return RouteScreen(dataProvider: _dataProvider);
      case 3:
        return AnalyticsScreen(dataProvider: _dataProvider);
      case 4:
        return const EmergencyScreen();
      case 5:
        return DailyPlanScreen(profile: _profile, dataProvider: _dataProvider);
      default:
        return DashboardScreen(
          profile: _profile,
          onEditProfile: _showEditProfileDialog,
          dataProvider: _dataProvider,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(2, 0))],
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.spa, color: Colors.teal, size: 24),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Breathe Well',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Nav items
                ...List.generate(_navItems.length, (i) {
                  final item = _navItems[i];
                  final isSelected = _selectedIndex == i;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Material(
                      color: isSelected ? Colors.teal.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _selectedIndex = i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: isSelected ? Colors.teal : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                item.label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.teal : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                // Data source indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _dataProvider.isRealData
                          ? Colors.green.withValues(alpha: 0.08)
                          : Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _dataProvider.isRealData
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _dataProvider.isRealData ? Icons.cloud_done : Icons.cloud_off,
                          size: 16,
                          color: _dataProvider.isRealData ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dataProvider.isRealData ? 'Live API Data' : 'Simulated Data',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _dataProvider.isRealData ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                        if (_dataProvider.loading)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Bottom info
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Rule-based risk calculation',
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.teal),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Weighted scoring using AQI, health condition, age & pollen data',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Container(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: _buildScreen(),
            ),
          ),
        ],
      ),
    );
  }
}
