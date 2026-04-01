import '../models/user_profile.dart';
import '../models/environment_data.dart';

enum RiskLevel { low, moderate, high }

class RiskResult {
  final double score; // 0-10
  final RiskLevel level;
  final String message;
  final List<String> factors;

  RiskResult({
    required this.score,
    required this.level,
    required this.message,
    required this.factors,
  });
}

class RiskCalculator {
  /// Weighted risk score calculation:
  /// - AQI factor: 40% weight
  /// - Health condition: 30% weight
  /// - Age factor: 15% weight
  /// - Pollen factor: 15% weight
  static RiskResult calculate(UserProfile profile, EnvironmentData env) {
    final factors = <String>[];

    // AQI factor (0-10) - 40% weight
    double aqiFactor = (env.aqi / 50).clamp(0, 10).toDouble();
    factors.add('AQI ${env.aqi} (${_aqiLabel(aqiFactor)})');

    // Health condition factor (0-10) - 30% weight
    double conditionFactor = _conditionScore(profile.condition);
    factors.add('${profile.condition.label} (${_conditionLabel(conditionFactor)})');

    // Age factor (0-10) - 15% weight
    double ageFactor = _ageScore(profile.age);
    factors.add('Age ${profile.age} (${_ageLabel(ageFactor)})');

    // Pollen factor (0-10) - 15% weight
    double pollenFactor = (env.pollenCount / 12).clamp(0, 10).toDouble();
    factors.add('Pollen ${env.pollenCount} (${_pollenLabel(pollenFactor)})');

    double score = (aqiFactor * 0.40) +
        (conditionFactor * 0.30) +
        (ageFactor * 0.15) +
        (pollenFactor * 0.15);
    score = score.clamp(0, 10);

    RiskLevel level;
    if (score <= 3.5) {
      level = RiskLevel.low;
    } else if (score <= 6.5) {
      level = RiskLevel.moderate;
    } else {
      level = RiskLevel.high;
    }

    String message = _generateMessage(level, profile.condition, env.aqi);

    return RiskResult(
      score: double.parse(score.toStringAsFixed(1)),
      level: level,
      message: message,
      factors: factors,
    );
  }

  static double _conditionScore(HealthCondition condition) {
    switch (condition) {
      case HealthCondition.normal:
        return 1.0;
      case HealthCondition.allergicRhinitis:
        return 4.0;
      case HealthCondition.sinusitis:
        return 5.0;
      case HealthCondition.bronchitis:
        return 6.0;
      case HealthCondition.postCovid:
        return 7.0;
      case HealthCondition.asthma:
        return 8.0;
      case HealthCondition.copd:
        return 9.0;
    }
  }

  static double _ageScore(int age) {
    if (age < 12) return 6.0;
    if (age < 18) return 3.0;
    if (age < 40) return 2.0;
    if (age < 60) return 5.0;
    return 8.0;
  }

  static String _aqiLabel(double f) => f <= 3 ? 'Low' : f <= 6 ? 'Moderate' : 'High';
  static String _conditionLabel(double f) => f <= 3 ? 'Low risk' : f <= 6 ? 'Moderate risk' : 'High risk';
  static String _ageLabel(double f) => f <= 3 ? 'Low risk' : f <= 6 ? 'Moderate risk' : 'Elevated risk';
  static String _pollenLabel(double f) => f <= 3 ? 'Low' : f <= 6 ? 'Moderate' : 'High';

  static String _generateMessage(RiskLevel level, HealthCondition condition, int aqi) {
    switch (level) {
      case RiskLevel.low:
        return 'Air quality is acceptable. Normal outdoor activities are safe for most individuals.';
      case RiskLevel.moderate:
        if (condition != HealthCondition.normal) {
          return 'Moderate risk for ${condition.label} patients. Limit prolonged outdoor exposure and carry medication.';
        }
        return 'Air quality is moderate. Sensitive individuals should consider reducing prolonged outdoor exertion.';
      case RiskLevel.high:
        if (condition != HealthCondition.normal) {
          return 'High risk for ${condition.label} patients. Avoid outdoor exposure. Use prescribed breathing exercises indoors.';
        }
        return 'Air quality is unhealthy. Avoid prolonged outdoor activities and stay indoors when possible.';
    }
  }
}
