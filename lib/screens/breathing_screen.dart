import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class BreathingExercise {
  final String name;
  final String description;
  final int inhaleSeconds;
  final int holdSeconds;
  final int exhaleSeconds;
  final List<HealthCondition> recommendedFor;

  const BreathingExercise({
    required this.name,
    required this.description,
    required this.inhaleSeconds,
    required this.holdSeconds,
    required this.exhaleSeconds,
    required this.recommendedFor,
  });

  int get cycleDuration => inhaleSeconds + holdSeconds + exhaleSeconds;
}

final _exercises = [
  BreathingExercise(
    name: 'Pursed-Lip Breathing',
    description: 'Slows breathing rate and improves ventilation. Recommended for asthma patients.',
    inhaleSeconds: 2,
    holdSeconds: 0,
    exhaleSeconds: 4,
    recommendedFor: [HealthCondition.asthma, HealthCondition.bronchitis],
  ),
  BreathingExercise(
    name: 'Diaphragmatic Breathing',
    description: 'Strengthens the diaphragm and decreases oxygen demand. Ideal for COPD management.',
    inhaleSeconds: 4,
    holdSeconds: 2,
    exhaleSeconds: 6,
    recommendedFor: [HealthCondition.copd],
  ),
  BreathingExercise(
    name: '4-7-8 Relaxation',
    description: 'Calming technique that reduces anxiety and promotes better oxygen exchange.',
    inhaleSeconds: 4,
    holdSeconds: 7,
    exhaleSeconds: 8,
    recommendedFor: [HealthCondition.normal, HealthCondition.sinusitis, HealthCondition.allergicRhinitis],
  ),
  BreathingExercise(
    name: 'Recovery Breathing',
    description: 'Gentle progressive breathing to rebuild lung capacity after respiratory illness.',
    inhaleSeconds: 3,
    holdSeconds: 3,
    exhaleSeconds: 5,
    recommendedFor: [HealthCondition.postCovid],
  ),
];

class BreathingScreen extends StatefulWidget {
  final UserProfile profile;
  const BreathingScreen({super.key, required this.profile});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> with SingleTickerProviderStateMixin {
  late BreathingExercise _selected;
  int _durationMinutes = 3;
  bool _isRunning = false;
  Timer? _timer;
  double _progress = 0;
  String _phase = 'Ready';
  int _elapsedSeconds = 0;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _selected = _getRecommended();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
  }

  BreathingExercise _getRecommended() {
    return _exercises.firstWhere(
      (e) => e.recommendedFor.contains(widget.profile.condition),
      orElse: () => _exercises[2],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startExercise() {
    setState(() {
      _isRunning = true;
      _elapsedSeconds = 0;
      _progress = 0;
    });
    _animController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final totalSeconds = _durationMinutes * 60;
      setState(() {
        _elapsedSeconds++;
        _progress = _elapsedSeconds / totalSeconds;
        final cyclePos = _elapsedSeconds % _selected.cycleDuration;
        if (cyclePos < _selected.inhaleSeconds) {
          _phase = 'Inhale';
        } else if (cyclePos < _selected.inhaleSeconds + _selected.holdSeconds) {
          _phase = 'Hold';
        } else {
          _phase = 'Exhale';
        }
      });
      if (_elapsedSeconds >= totalSeconds) {
        _stopExercise();
      }
    });
  }

  void _stopExercise() {
    _timer?.cancel();
    _animController.stop();
    setState(() {
      _isRunning = false;
      _phase = 'Complete';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Breathing Exercises', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Auto-selected for: ${widget.profile.condition.label}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.teal),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise selector
              Expanded(
                flex: 1,
                child: _buildExerciseList(theme),
              ),
              const SizedBox(width: 24),
              // Animation + controls
              Expanded(
                flex: 2,
                child: _buildExercisePanel(theme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Techniques', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._exercises.map((e) {
            final isSelected = e == _selected;
            final isRecommended = e.recommendedFor.contains(widget.profile.condition);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isSelected ? Colors.teal.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _isRunning ? null : () => setState(() => _selected = e),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? Colors.teal : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.name, style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              )),
                              if (isRecommended)
                                Text('Recommended', style: theme.textTheme.bodySmall?.copyWith(color: Colors.teal)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExercisePanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text(_selected.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_selected.description, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Pattern: ${_selected.inhaleSeconds}s inhale – ${_selected.holdSeconds}s hold – ${_selected.exhaleSeconds}s exhale',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 32),

          // Breathing animation circle
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final scale = _isRunning ? 0.7 + (_animController.value * 0.3) : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.teal.withValues(alpha: 0.3),
                        Colors.teal.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.teal.withValues(alpha: 0.15),
                        border: Border.all(color: Colors.teal, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          _phase,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          if (_isRunning) ...[
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.teal.withValues(alpha: 0.1),
              color: Colors.teal,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '${_elapsedSeconds ~/ 60}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')} / $_durationMinutes:00',
              style: theme.textTheme.bodyMedium,
            ),
          ],

          const SizedBox(height: 16),

          // Duration control
          if (!_isRunning)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Duration: ', style: theme.textTheme.bodyMedium),
                ...([2, 3, 5, 10]).map((d) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('${d}m'),
                    selected: _durationMinutes == d,
                    onSelected: (_) => setState(() => _durationMinutes = d),
                    selectedColor: Colors.teal.withValues(alpha: 0.2),
                  ),
                )),
              ],
            ),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: _isRunning ? _stopExercise : _startExercise,
            icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow),
            label: Text(_isRunning ? 'Stop' : 'Start Exercise'),
            style: FilledButton.styleFrom(
              backgroundColor: _isRunning ? Colors.red : Colors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
