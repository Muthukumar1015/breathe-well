import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> with SingleTickerProviderStateMixin {
  bool _gpsLoading = false;
  String? _locationStatus;
  double? _lat, _lon;
  late AnimationController _pulseController;

  final List<Map<String, String>> _emergencyContacts = [
    {'name': 'Mom', 'phone': '+919876543210', 'relation': 'Mother'},
    {'name': 'Dad', 'phone': '+919876543211', 'relation': 'Father'},
    {'name': 'Dr. Sharma', 'phone': '+919876543212', 'relation': 'Doctor'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _autoDetectLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _autoDetectLocation() async {
    setState(() {
      _gpsLoading = true;
      _locationStatus = 'Detecting...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _locationStatus = 'GPS disabled'; _gpsLoading = false; });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _locationStatus = 'Permission denied'; _gpsLoading = false; });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() { _locationStatus = 'Permission denied'; _gpsLoading = false; });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _lat = position.latitude;
        _lon = position.longitude;
        _locationStatus = 'Location detected';
        _gpsLoading = false;
      });
    } catch (e) {
      setState(() { _locationStatus = 'Detection failed'; _gpsLoading = false; });
    }
  }

  Future<void> _openNearbyHospitals() async {
    final url = _lat != null
        ? 'https://www.google.com/maps/search/hospitals+near+me/@$_lat,$_lon,14z'
        : 'https://www.google.com/maps/search/hospitals+near+me';
    await _launchUrl(url);
  }

  Future<void> _openNearbyPharmacies() async {
    final url = _lat != null
        ? 'https://www.google.com/maps/search/pharmacy+near+me/@$_lat,$_lon,14z'
        : 'https://www.google.com/maps/search/pharmacy+near+me';
    await _launchUrl(url);
  }

  Future<void> _openNearbyClinics() async {
    final url = _lat != null
        ? 'https://www.google.com/maps/search/clinic+near+me/@$_lat,$_lon,14z'
        : 'https://www.google.com/maps/search/clinic+near+me';
    await _launchUrl(url);
  }

  Future<void> _callNumber(String phone) async {
    await _launchUrl('tel:$phone');
  }

  Future<void> _sendSms(String phone, String message) async {
    await _launchUrl('sms:$phone?body=${Uri.encodeComponent(message)}');
  }

  Future<void> _openWhatsApp(String phone, String message) async {
    final cleanPhone = phone.replaceAll('+', '').replaceAll(' ', '');
    await _launchUrl('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
  }

  Future<void> _shareLocation() async {
    if (_lat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not detected yet.'), backgroundColor: Colors.orange),
      );
      return;
    }
    final mapLink = 'https://www.google.com/maps?q=$_lat,$_lon';
    final message = 'EMERGENCY! I need help. My location: $mapLink';
    if (_emergencyContacts.isNotEmpty) {
      await _openWhatsApp(_emergencyContacts[0]['phone']!, message);
    }
  }

  // ─── Add / Edit / Delete Emergency Contacts ─────────────────────
  void _showAddContactDialog() {
    _showContactDialog(null, -1);
  }

  void _showEditContactDialog(Map<String, String> contact, int index) {
    _showContactDialog(contact, index);
  }

  void _showContactDialog(Map<String, String>? contact, int index) {
    final nameCtrl = TextEditingController(text: contact?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: contact?['phone'] ?? '');
    final relationCtrl = TextEditingController(text: contact?['relation'] ?? '');
    final isEdit = contact != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Contact' : 'Add Contact'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+91XXXXXXXXXX',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationCtrl,
                decoration: InputDecoration(
                  labelText: 'Relation',
                  hintText: 'Mother, Father, Doctor...',
                  prefixIcon: const Icon(Icons.group),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (isEdit)
            TextButton(
              onPressed: () {
                setState(() => _emergencyContacts.removeAt(index));
                Navigator.pop(ctx);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              final relation = relationCtrl.text.trim();
              if (name.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name and phone are required'), backgroundColor: Colors.orange),
                );
                return;
              }
              setState(() {
                if (isEdit) {
                  _emergencyContacts[index] = {'name': name, 'phone': phone, 'relation': relation};
                } else {
                  _emergencyContacts.add({'name': name, 'phone': phone, 'relation': relation});
                }
              });
              Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
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
                child: Text('Emergency Panel', style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 22 : null,
                )),
              ),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _lat != null
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.05 + _pulseController.value * 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _lat != null ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_gpsLoading)
                        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        Icon(_lat != null ? Icons.gps_fixed : Icons.gps_off, size: 14,
                            color: _lat != null ? Colors.green : Colors.orange),
                      const SizedBox(width: 5),
                      Text(_locationStatus ?? 'Detecting...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _lat != null ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w600, fontSize: 11,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),

          // SOS Banner
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 14 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.red.shade600.withValues(alpha: 0.9 + _pulseController.value * 0.1),
                  Colors.red.shade800,
                ]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                  color: Colors.red.withValues(alpha: 0.2 + _pulseController.value * 0.1),
                  blurRadius: 20, offset: const Offset(0, 4),
                )],
              ),
              child: isMobile
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.emergency, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Emergency SOS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text('Tap for immediate help', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _callNumber('102'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.phone, color: Colors.red.shade700, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Call Ambulance 102', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.emergency, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Emergency SOS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              Text('Tap buttons below for immediate help', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _callNumber('102'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(Icons.phone, color: Colors.red.shade700, size: 18),
                                  const SizedBox(width: 6),
                                  Text('Call 102', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),

          // Facilities + Contacts
          if (isMobile) ...[
            _buildNearbyFacilities(theme),
            const SizedBox(height: 16),
            _buildEmergencyContacts(theme, isMobile),
            const SizedBox(height: 16),
            _buildBreathingSteps(theme),
            const SizedBox(height: 16),
            _buildMedicationAwareness(theme),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildNearbyFacilities(theme)),
                const SizedBox(width: 20),
                Expanded(child: _buildEmergencyContacts(theme, isMobile)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildBreathingSteps(theme)),
                const SizedBox(width: 20),
                Expanded(child: _buildMedicationAwareness(theme)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNearbyFacilities(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              const Icon(Icons.map, color: Colors.blue, size: 22),
              const SizedBox(width: 8),
              Text('Nearby Facilities', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Opens Google Maps with your location',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 16),
          _facilityButton(theme, icon: Icons.local_hospital, title: 'Nearest Hospital',
              subtitle: 'Find hospitals nearby', color: Colors.red, onTap: _openNearbyHospitals),
          const SizedBox(height: 10),
          _facilityButton(theme, icon: Icons.local_pharmacy, title: 'Nearest Pharmacy',
              subtitle: 'Find pharmacies & medical stores', color: Colors.green, onTap: _openNearbyPharmacies),
          const SizedBox(height: 10),
          _facilityButton(theme, icon: Icons.medical_services, title: 'Nearest Clinic',
              subtitle: 'Find clinics & health centers', color: Colors.blue, onTap: _openNearbyClinics),
          const SizedBox(height: 10),
          _facilityButton(theme, icon: Icons.share_location, title: 'Share Location',
              subtitle: 'Send via WhatsApp', color: Colors.purple, onTap: _shareLocation),
        ],
      ),
    );
  }

  Widget _facilityButton(ThemeData theme, {
    required IconData icon, required String title, required String subtitle,
    required Color color, required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, size: 14, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyContacts(ThemeData theme, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              const Icon(Icons.contacts, color: Colors.deepOrange, size: 22),
              const SizedBox(width: 8),
              Text('Emergency Contacts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text('One-tap call or message',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
              ),
              Material(
                color: Colors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _showAddContactDialog,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_add, size: 16, color: Colors.teal),
                        SizedBox(width: 4),
                        Text('Add', style: TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...List.generate(_emergencyContacts.length, (i) => _contactCard(theme, _emergencyContacts[i], isMobile, i)),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          Text('Government Helplines', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _helplineButton(theme, '102', 'Ambulance', Colors.red),
          const SizedBox(height: 6),
          _helplineButton(theme, '108', 'Emergency Medical', Colors.blue),
          const SizedBox(height: 6),
          _helplineButton(theme, '112', 'National Emergency', Colors.orange),
        ],
      ),
    );
  }

  Widget _contactCard(ThemeData theme, Map<String, String> contact, bool isMobile, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isMobile ? 16 : 20,
            backgroundColor: Colors.deepOrange.withValues(alpha: 0.1),
            child: Text(contact['name']![0],
                style: TextStyle(color: Colors.deepOrange.shade700, fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact['name']!, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : null)),
                Text(isMobile ? contact['relation']! : '${contact['relation']} • ${contact['phone']}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11)),
              ],
            ),
          ),
          _iconAction(Icons.edit, Colors.grey, () => _showEditContactDialog(contact, index)),
          const SizedBox(width: 4),
          _iconAction(Icons.phone, Colors.green, () => _callNumber(contact['phone']!)),
          const SizedBox(width: 4),
          _iconAction(Icons.message, Colors.blue,
              () => _sendSms(contact['phone']!, 'EMERGENCY! I need help.')),
          const SizedBox(width: 4),
          _iconAction(Icons.chat, const Color(0xFF25D366),
              () => _openWhatsApp(contact['phone']!, 'EMERGENCY! I need help urgently.')),
        ],
      ),
    );
  }

  Widget _iconAction(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _helplineButton(ThemeData theme, String number, String label, Color color) {
    return Material(
      color: color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _callNumber(number),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.phone, size: 16, color: color),
              const SizedBox(width: 10),
              Text(number, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
              Icon(Icons.call, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreathingSteps(ThemeData theme) {
    final steps = [
      {'title': 'Stop & Sit Upright', 'desc': 'Find a comfortable position and sit upright to open your airways.'},
      {'title': 'Purse Your Lips', 'desc': 'Breathe in slowly through your nose for 2 seconds.'},
      {'title': 'Exhale Slowly', 'desc': 'Exhale through pursed lips for 4 seconds.'},
      {'title': 'Repeat 5 Times', 'desc': 'Continue this pattern. Focus only on your breath.'},
      {'title': 'Seek Help if No Relief', 'desc': 'If no improvement in 5 minutes, call emergency.'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emergency, color: Colors.red.shade600, size: 24),
              const SizedBox(width: 8),
              Text('Emergency Breathing', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle, border: Border.all(color: Colors.red.shade200)),
                  child: Center(child: Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700, fontSize: 12))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(steps[i]['title']!, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(steps[i]['desc']!, style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMedicationAwareness(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              const Icon(Icons.medication, color: Colors.orange, size: 22),
              const SizedBox(width: 8),
              Text('Medication Awareness', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('For awareness only – not a prescription.',
                    style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, fontSize: 11))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _medicationItem(theme, 'Inhaler (Salbutamol)', 'Quick-relief bronchodilator', Icons.air),
          const SizedBox(height: 8),
          _medicationItem(theme, 'Antihistamines', 'For allergic reactions', Icons.healing),
          const SizedBox(height: 8),
          _medicationItem(theme, 'Nasal Spray', 'For sinusitis management', Icons.sanitizer),
          const SizedBox(height: 8),
          _medicationItem(theme, 'Steam Inhalation', 'Non-medication relief', Icons.water_drop),
        ],
      ),
    );
  }

  Widget _medicationItem(ThemeData theme, String name, String desc, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.orange.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(desc, style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
