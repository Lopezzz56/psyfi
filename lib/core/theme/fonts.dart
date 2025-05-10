import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AFonts {
  static TextStyle heading = GoogleFonts.openSans(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static TextStyle subheading = GoogleFonts.openSans(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static TextStyle body = GoogleFonts.roboto(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    color: Colors.black,
  );

  static TextStyle caption = GoogleFonts.openSans(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    color: const Color.fromARGB(255, 95, 94, 94),
  );
}
