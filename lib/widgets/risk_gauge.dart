import 'dart:math';
import 'package:flutter/material.dart';
import '../services/risk_calculator.dart';

class RiskGauge extends StatelessWidget {
  final RiskResult result;
  const RiskGauge({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (result.level) {
      RiskLevel.low => Colors.green,
      RiskLevel.moderate => Colors.orange,
      RiskLevel.high => Colors.red,
    };
    final label = switch (result.level) {
      RiskLevel.low => 'Low Risk',
      RiskLevel.moderate => 'Moderate Risk',
      RiskLevel.high => 'High Risk',
    };

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety, color: color, size: 22),
              const SizedBox(width: 8),
              Text('Respiratory Risk Score', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),

          // Gauge
          SizedBox(
            width: 180,
            height: 110,
            child: CustomPaint(
              painter: _GaugePainter(score: result.score, color: color),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${result.score}/10',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Color legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dot(Colors.green, '0-3.5 Low'),
              const SizedBox(width: 16),
              _dot(Colors.orange, '3.5-6.5 Mod'),
              const SizedBox(width: 16),
              _dot(Colors.red, '6.5-10 High'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;

  _GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      bgPaint,
    );

    // Green zone
    final greenPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi, pi * 0.35, false, greenPaint);

    // Orange zone
    final orangePaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi + pi * 0.35, pi * 0.3, false, orangePaint);

    // Red zone
    final redPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi + pi * 0.65, pi * 0.35, false, redPaint);

    // Needle
    final needleAngle = pi + (score / 10) * pi;
    final needleEnd = Offset(
      center.dx + radius * 0.7 * cos(needleAngle),
      center.dy + radius * 0.7 * sin(needleAngle),
    );
    final needlePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);

    // Center dot
    canvas.drawCircle(center, 6, Paint()..color = color);
    canvas.drawCircle(center, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.score != score || oldDelegate.color != color;
}
