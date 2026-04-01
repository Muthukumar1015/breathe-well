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

  const DashboardScreen({
    super.key,
    required this.profile,
    required this.onEditProfile,
    required this.dataProvider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final envData = dataProvider.envData;
    final riskResult = RiskCalculator.calculate(profile, envData);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Dashboard', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (dataProvider.loading)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              if (dataProvider.isRealData)
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
                      Text('Live Data', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: dataProvider.loading ? null : () => dataProvider.refresh(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh data',
              ),
            ],
          ),
          if (dataProvider.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(dataProvider.error!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange)),
            ),
          const SizedBox(height: 24),

          // Top row: Profile + AQI
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: ProfileCard(
                  profile: profile,
                  onEdit: onEditProfile,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: AqiCard(data: envData),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Risk Rating + Smart Message
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: RiskGauge(result: riskResult),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: _buildSmartMessage(theme, riskResult),
              ),
            ],
          ),
        ],
      ),
    );
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
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
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
            child: Text(
              riskResult.message,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
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
                Text(f, style: theme.textTheme.bodyMedium),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
