import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  final List<String> messages;
  final Duration messageDuration;
  final Color backgroundColor;
  final Color progressColor;
  final TextStyle? textStyle;

  const LoadingScreen({
    Key? key,
    this.messages = const [
      "We are here...",
      "Almost there...",
      "Hang tight..."
    ],
    this.messageDuration = const Duration(seconds: 2),
    this.backgroundColor = Colors.white,
    this.progressColor = Colors.blueAccent,
    this.textStyle,
  }) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  int _currentMessageIndex = 0;
  Timer? _timer;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _startMessageLoop();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // 1 rotation per second
    )..repeat();

    // Stop after 4 rotations (4 seconds)
    Future.delayed(const Duration(seconds: 4), () {
      _controller.stop();
    });
  }

  void _startMessageLoop() {
    _timer = Timer.periodic(widget.messageDuration, (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % widget.messages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: child,
                );
              },
              child: Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.progressColor,
                  boxShadow: [
                    BoxShadow(
                      color: widget.progressColor.withAlpha(60),
                      blurRadius: 16,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/psyfyimg.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80), // distance between animation and text
            Text(
              widget.messages[_currentMessageIndex],
              textAlign: TextAlign.center,
              style: widget.textStyle ??
                  const TextStyle(
                    fontSize: 20,
                    fontFamily: 'Cormorant Garamond',
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
