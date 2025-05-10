import 'package:flutter/material.dart';
import 'package:psy_fi/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:psy_fi/core/theme/colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final TextStyle? textStyle;
  final double? width;
  
  final Widget? child;
  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.color,
    this.textStyle,
    this.width, 
    this.child, // Add this line
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: width ?? double.infinity, // Use full width by default
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          text,
          style: textStyle ??
              GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
      ),
    );
  }
}
