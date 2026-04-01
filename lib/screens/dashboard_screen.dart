import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/risk_calculator.dart';
import '../services/data_provider.dart';
import '../widgets/risk_gauge.dart';
import '../widgets/profile_card.dart';
import '../widgets/aqi_card.dart';

class DashboardScreen extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEditProfile;
  final DataProvider dataProvider;
  final VoidCallback onEmergency;

  const DashboardScreen({
    super.key,
    required this.profile,
    required this.onEditProfile,
    required this.dataProvider,
    required this.onEmergency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final envData = dataProvider.envData;
    final riskResult = RiskCalculator.calculate(profile, envData);
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
                child: Text('Dashboard', style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 22 : null,
                )),
              ),
              if (dataProvider.loading)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              // GPS + Data source indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: dataProvider.isRealData
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dataProvider.isRealData
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      dataProvider.gpsDetected ? Icons.gps_fixed : Icons.cloud_done,
                      size: 13,
                      color: dataProvider.isRealData ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dataProvider.isRealData
                          ? (dataProvider.gpsDetected ? 'GPS Live' : 'Live')
                          : 'Simulated',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: dataProvider.isRealData ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold, fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: dataProvider.loading ? null : () => dataProvider.refresh(),
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh data',
              ),
            ],
          ),

          // Error / status messages
          if (dataProvider.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(dataProvider.error!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange.shade800))),
                  ],
                ),
              ),
            ),

          // Last updated time
          if (dataProvider.lastUpdated != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Last updated: ${_formatTime(dataProvider.lastUpdated!)} • ${dataProvider.cityName} • Auto-refreshes every 10 min',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10,
                ),
              ),
            ),

          SizedBox(height: isMobile ? 12 : 20),

          // Emergency SOS Button
          GestureDetector(
            onTap: onEmergency,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.red.shade600, Colors.red.shade800]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emergency, color: Colors.white, size: 26),
                  const SizedBox(width: 12),
                  Text('Emergency Breathing Help',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 15 : 17,
                      )),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),

          SizedBox(height: isMobile ? 16 : 24),

          // Profile + AQI
          if (isMobile) ...[
            ProfileCard(profile: profile, onEdit: onEditProfile),
            const SizedBox(height: 16),
            AqiCard(data: envData),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: ProfileCard(profile: profile, onEdit: onEditProfile)),
                const SizedBox(width: 20),
                Expanded(child: AqiCard(data: envData)),
              ],
            ),

          SizedBox(height: isMobile ? 16 : 24),

          // Risk + Smart Message
          if (isMobile) ...[
            RiskGauge(result: riskResult),
            const SizedBox(height: 16),
            _buildSmartMessage(theme, riskResult),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: RiskGauge(result: riskResult)),
                const SizedBox(width: 20),
                Expanded(child: _buildSmartMessage(theme, riskResult)),
              ],
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }

  Widget _buildSmartMessage(ThemeData theme, RiskResult riskResult) {
    final color = switch (riskResult.level) {
      RiskLevel.low => Colors.green,
      RiskLevel.moderate => Colors.orange,
      RiskLevel.high => Colors.red,
    };

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: color, size: 20),
              const SizedBox(width: 8),
              Text('Smart Advisory', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: color, width: 4)),
            ),
            child: Text(riskResult.message, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
          ),
          const SizedBox(height: 16),
          Text('Contributing Factors:', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...riskResult.factors.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.circle, size: 6, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Expanded(child: Text(f, style: theme.textTheme.bodyMedium)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
