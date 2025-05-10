import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

class AnimatedArrow extends StatefulWidget {
  const AnimatedArrow({Key? key}) : super(key: key);

  @override
  _AnimatedArrowState createState() => _AnimatedArrowState();
}

class _AnimatedArrowState extends State<AnimatedArrow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0, 0.1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Center(
        child: Icon(
          Icons.arrow_downward,
          size: 40,
          color: Colors.lightBlueAccent, // Light blue color
        ),
      ),
    );
  }
}
