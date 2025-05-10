import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:psy_fi/core/theme/colors.dart';

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  String _currentPhase = 'Inhale';
  int _phaseIndex = 0;

  final List<_BreathingPhase> _phases = [
    _BreathingPhase('🫁 Inhale...', 4, 1.0, 1.4),
    _BreathingPhase('✋ Hold...', 7, 1.4, 1.4),
    _BreathingPhase('💨 Exhale...', 8, 1.4, 0.8),
  ];

  @override
  void initState() {
    super.initState();
    _startPhaseCycle();
  }

  void _startPhaseCycle() {
    final phase = _phases[_phaseIndex];
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: phase.durationSeconds),
    );

    _scaleAnimation = Tween<double>(
      begin: phase.scaleStart,
      end: phase.scaleEnd,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    setState(() {
      _currentPhase = phase.label;
    });

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.dispose();
        _phaseIndex = (_phaseIndex + 1) % _phases.length;
        _startPhaseCycle();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return Scaffold(
            backgroundColor: Colors.white,

            appBar: AppBar(
                    backgroundColor: Colors.white,

        title: Text(
          'Breathing Exercises',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffe0f7fa), Color.fromARGB(255, 196, 214, 244)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        height: 250,
                        width: 250,
                        decoration: BoxDecoration(
                          color: AColors.primary.withOpacity(0.7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AColors.primary.withOpacity(0.4),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.spa, size: 100, color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 100),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                  child: Text(
                    _currentPhase,
                    key: ValueKey(_currentPhase),
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathingPhase {
  final String label;
  final int durationSeconds;
  final double scaleStart;
  final double scaleEnd;

  _BreathingPhase(this.label, this.durationSeconds, this.scaleStart, this.scaleEnd);
}
