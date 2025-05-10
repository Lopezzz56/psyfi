
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';


class ChatTile extends StatelessWidget {
  final String name;
  final String email;
  final String? imageUrl;
  final String? lastMessage;
  final int unseenCount;
  final VoidCallback onTap;

  const ChatTile({
    Key? key,
    required this.name,
    required this.email,
    this.imageUrl,
    this.lastMessage,
    this.unseenCount = 0,
    required this.onTap,
  }) : super(key: key);


  @override

LinearGradient getRandomGradient() {
  final gradients = [
    LinearGradient(colors: [Colors.purple, Colors.deepPurpleAccent]),
    LinearGradient(colors: [Colors.blue, Colors.lightBlueAccent]),
    LinearGradient(colors: [Colors.orange, Colors.deepOrangeAccent]),
    LinearGradient(colors: [Colors.teal, Colors.cyan]),
    LinearGradient(colors: [Colors.pink, Colors.purpleAccent]),
    LinearGradient(colors: [Colors.green, Colors.lightGreenAccent]),
  ];

  final random = Random();
  return gradients[random.nextInt(gradients.length)];
}
TextStyle _getRandomFontStyle() {
  final random = Random();
  List<TextStyle> fontStyles = [
  GoogleFonts.dancingScript(fontSize: 28, fontWeight: FontWeight.bold),
    GoogleFonts.lobster(fontSize: 30, fontWeight: FontWeight.w600),
    GoogleFonts.pacifico(fontSize: 32, fontWeight: FontWeight.normal),
    GoogleFonts.playball(fontSize: 26, fontStyle: FontStyle.italic),
    GoogleFonts.raleway(fontSize: 24, fontWeight: FontWeight.w500),
    GoogleFonts.abrilFatface(fontSize: 34, fontWeight: FontWeight.w700),
  ];
  return fontStyles[random.nextInt(fontStyles.length)];
}
Widget build(BuildContext context) {
  String _capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  String initialLetter = name.isNotEmpty ? name[0].toUpperCase() : 'A';

  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(
    color: Colors.blueAccent.withAlpha((0.15 * 255).round()), // 15% opaque gray
    width: 2,
  ),
  boxShadow: [
    BoxShadow(
      color: Colors.blueAccent.withAlpha((0.07 * 255).round()), // 7% opaque black
      blurRadius: 12,
      spreadRadius: 2,
      offset: const Offset(0, 6),
    ),
  ],
),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: getRandomGradient(),
            ),
            alignment: Alignment.center,
            child: Text(
              initialLetter,
              style: _getRandomFontStyle().copyWith(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _capitalizeFirstLetter(name),
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastMessage ?? email,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          if (unseenCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.blue,
                radius: 12,
                child: Text(
                  '$unseenCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

}
