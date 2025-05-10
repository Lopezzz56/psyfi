import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showText = false;

@override
void initState() {
  super.initState();

  _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  Future.delayed(const Duration(seconds: 4), () {
    _controller.stop();
  });

  Future.delayed(const Duration(milliseconds: 6500), () {
    if (mounted) {
      setState(() {
        _showText = true;
      });
    }
  });

  Future.delayed(const Duration(seconds: 12), () {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/home'); // GoRouter is now available
      }
    });
  });
}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _showText
            ? Text(
                'PSY FY',
                style: GoogleFonts.kenia(
                  fontSize: 120,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                  color: Colors.blueAccent,
                ),
              )
            : AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.value * 2 * math.pi,
                    child: child,
                  );
                },
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withAlpha(60),
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
      ),
    );
  }
}
