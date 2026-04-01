import 'package:flutter/material.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Emergency Panel', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emergency breathing steps
              Expanded(flex: 1, child: _buildBreathingSteps(theme)),
              const SizedBox(width: 20),
              // Quick actions
              Expanded(flex: 1, child: _buildQuickActions(theme)),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nearest hospitals
              Expanded(flex: 1, child: _buildNearestHospitals(theme)),
              const SizedBox(width: 20),
              // Medication awareness
              Expanded(flex: 1, child: _buildMedicationAwareness(theme)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingSteps(ThemeData theme) {
    final steps = [
      {'title': 'Stop & Sit Upright', 'desc': 'Find a comfortable position and sit upright to open your airways.'},
      {'title': 'Purse Your Lips', 'desc': 'Breathe in slowly through your nose for 2 seconds.'},
      {'title': 'Exhale Slowly', 'desc': 'Exhale through pursed lips for 4 seconds, like blowing a candle.'},
      {'title': 'Repeat 5 Times', 'desc': 'Continue this pattern. Focus only on your breath.'},
      {'title': 'Seek Help if No Relief', 'desc': 'If breathing does not improve in 5 minutes, call emergency services.'},
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
              Text('Emergency Breathing Steps', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Center(child: Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700, fontSize: 13))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(steps[i]['title']!, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(steps[i]['desc']!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
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

  Widget _buildQuickActions(ThemeData theme) {
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
          Text('Quick Actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _actionButton(theme, Icons.phone, 'Call Emergency Contact', 'Mom – +91 98765 43210', Colors.red),
          const SizedBox(height: 12),
          _actionButton(theme, Icons.local_hospital, 'Call Ambulance', '102 / 108', Colors.blue),
          const SizedBox(height: 12),
          _actionButton(theme, Icons.medical_services, 'Nearest Hospital', 'Lilavati Hospital – 1.2 km', Colors.green),
          const SizedBox(height: 12),
          _actionButton(theme, Icons.share_location, 'Share Live Location', 'Send to emergency contact', Colors.purple),
        ],
      ),
    );
  }

  Widget _actionButton(ThemeData theme, IconData icon, String title, String subtitle, Color color) {
    return Material(
      color: color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNearestHospitals(ThemeData theme) {
    final hospitals = [
      {'name': 'Lilavati Hospital', 'dist': '1.2 km', 'type': 'Multi-Specialty'},
      {'name': 'Holy Family Hospital', 'dist': '2.8 km', 'type': 'General'},
      {'name': 'Hinduja Hospital', 'dist': '3.5 km', 'type': 'Pulmonology Center'},
    ];

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
              const Icon(Icons.local_hospital, color: Colors.blue, size: 22),
              const SizedBox(width: 8),
              Text('Nearest Hospitals', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...hospitals.map((h) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.place, color: Colors.blue, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h['name']!, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(h['type']!, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(h['dist']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('This is for awareness only – not a prescription.', style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _medicationItem(theme, 'Inhaler (Salbutamol)', 'Quick-relief bronchodilator for acute symptoms', Icons.air),
          const SizedBox(height: 8),
          _medicationItem(theme, 'Antihistamines', 'For allergic rhinitis and pollen-triggered reactions', Icons.healing),
          const SizedBox(height: 8),
          _medicationItem(theme, 'Nasal Spray', 'Corticosteroid spray for sinusitis management', Icons.sanitizer),
          const SizedBox(height: 8),
          _medicationItem(theme, 'Steam Inhalation', 'Non-medication relief for congestion', Icons.water_drop),
        ],
      ),
    );
  }

  Widget _medicationItem(ThemeData theme, String name, String desc, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.orange.withValues(alpha: 0.7)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text(desc, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ),
      ],
    );
  }
}
