import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:psy_fi/core/components/custom_button.dart';
class BreathingInfoScreen extends StatelessWidget {
  const BreathingInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Breathing Exercise Info',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💨 Why Breathing Exercises Matter',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your breath is always with you — and it’s more powerful than you think.\n\n'
              'Deep breathing is like a reset button for your mind and body. It sends signals to your nervous system that it’s safe to relax.\n\n'
              '🧘 When practiced regularly, breathing exercises can:\n'
              '• Calm racing thoughts and anxiety\n'
              '• Slow your heart rate and reduce blood pressure\n'
              '• Improve focus, clarity, and mood\n\n'
              'Take a deep breath now. Inhale slowly… hold… and exhale gently.\n\n'
              'That’s the beginning of your calm.',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: CustomButton(
                text: 'Next',
                onPressed: () => context.push('/breathing-exercise'),
                textStyle: GoogleFonts.cormorantGaramond(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
