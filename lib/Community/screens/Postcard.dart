import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool liked;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    liked = widget.post["liked"] ?? false;
    likeCount = widget.post["likes"] ?? 0;
  }

  void toggleLike() {
    setState(() {
      liked = !liked;
      likeCount += liked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    String message = widget.post["message"] ?? "";
    String? title;
    String? highlightedPart;

    // Check if the message has two paragraphs (separated by a newline)
    final messageParts = message.split('\n\n');
    if (messageParts.length == 2) {
      title = messageParts[0].trim();
      highlightedPart = messageParts[1].trim();
    } else {
      // If no clear title, consider the first line as a potential title
      final lines = message.split('\n');
      if (lines.isNotEmpty && lines.length > 1) {
        title = lines[0].trim();
        highlightedPart = lines.skip(1).join('\n').trim();
      } else {
        highlightedPart = message; // If only one line, highlight it all
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.post["name"] ?? "",
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.post["username"] ?? "",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (title != null && title.isNotEmpty)
              Text(
                title,
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
            if (title != null && title.isNotEmpty) const SizedBox(height: 8),
            if (highlightedPart != null && highlightedPart.isNotEmpty)
              Text(
                highlightedPart,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: toggleLike,
                  child: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? Colors.red : Colors.black,
                  ),
                ),
                const SizedBox(width: 4),
                Text(likeCount.toString()),
                const SizedBox(width: 16),
                Icon(Icons.chat_bubble_outline),
                const SizedBox(width: 4),
                Text((widget.post["comments"] ?? 0).toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}