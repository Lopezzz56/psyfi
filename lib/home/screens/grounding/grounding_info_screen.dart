import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:psy_fi/core/components/custom_button.dart';
class GroundingInfoScreen extends StatelessWidget {
  const GroundingInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                'Grounding Techniques',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌱 Why Grounding Matters',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text:
                                'Feeling overwhelmed? Anxious? Grounding techniques gently bring your attention back to the present moment — helping you breathe easier and think more clearly.\n\n',
                          ),
                          TextSpan(
                            text:
                                '🌟 One simple method to try: the 5-4-3-2-1 technique.\n\n',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text:
                                '• 5 things you can see\n• 4 things you can touch\n• 3 things you can hear\n• 2 things you can smell\n• 1 thing you can taste\n\n',
                          ),
                          TextSpan(
                            text:
                                'This powerful exercise helps reconnect your senses with the present, giving your mind a break from racing thoughts or stress.',
                          ),
                          TextSpan(
                            text:
                                '\n\n📚 Sources:\n- Medical News Today: Grounding Techniques\n- URMC: 5-4-3-2-1 Coping Technique for Anxiety',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      style: TextStyle(fontSize: 18, height: 1.6),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: CustomButton(
                        text: 'Next',
                        onPressed: () {
                          context.push('/grounding-form');
                        },
                        textStyle: GoogleFonts.cormorantGaramond(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 100), // extra spacing at bottom
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
