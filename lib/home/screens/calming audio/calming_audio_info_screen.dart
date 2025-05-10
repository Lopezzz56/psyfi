import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:psy_fi/core/components/custom_button.dart';
class CalmingAudioInfoScreen extends StatelessWidget {
  const CalmingAudioInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Calming Audio Info',
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
              '🎧 The Soothing Power of Sound',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Feeling tense or mentally drained?\n\n'
              'Let calming audio become your escape hatch. Sounds like rainfall, ocean waves, soft piano, or ambient tones can shift your mood, reduce stress, and help you reconnect with yourself.\n\n'
              '🌿 When used regularly, calming sounds can:\n'
              '• Ease anxiety and quiet your thoughts\n'
              '• Boost sleep quality and emotional balance\n'
              '• Trigger relaxation responses in your brain\n\n'
              'It’s not just background noise — it’s a tool for peace. Try adding a few minutes of soothing audio to your day and notice how your mind and body respond.',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: CustomButton(
                text: 'Next',
                onPressed: () => context.push('/calming-audio'),
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
