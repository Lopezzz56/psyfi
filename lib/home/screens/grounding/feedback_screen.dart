import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:psy_fi/core/components/custom_button.dart';
import 'package:psy_fi/core/theme/colors.dart';
import 'grounding_form_screen.dart';

class FeedbackScreen extends StatelessWidget {
  final String feedbackMessage;

  const FeedbackScreen({Key? key, required this.feedbackMessage})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'AI Feedback',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.feedback_outlined, size: 60, color: AColors.primary),
              const SizedBox(height: 30),
              Text(
                feedbackMessage,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              CustomButton(
                text: 'Try Again',
                onPressed: () => context.go('/grounding-info'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
