import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:psy_fi/core/components/loading_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    liked = widget.post["liked_by_user"] == true;
    likeCount = widget.post["likes"] ?? 0;
  }

  void toggleLike() async {
    setState(() {
      liked = !liked;
      likeCount += liked ? 1 : -1;
    });

    try {
      await Supabase.instance.client
          .from('motivations')
          .update({'likes': likeCount})
          .eq('id', widget.post['id']);
    } catch (e) {
      print('Error updating likes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.post["content"] as Map<String, dynamic>;
    final title = content["title"];
    final highlight = content["highlight"];
String? body = content["body"]; // Make body nullable initially

 // Process the body to replace escaped newlines with actual newlines
if (body != null) {
body = body.replaceAll('\\n', '\n');
}
    final imageUrls =
        widget.post["motive_url"] != null && widget.post["motive_url"] is List
            ? List<String>.from(widget.post["motive_url"])
            : [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), ),
      elevation: 4,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // No padding for the image
          if (imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: SizedBox(
                height: 280,
                width: double.infinity,
                child: PageView.builder(
                  itemCount: imageUrls.length,
                  controller: PageController(viewportFraction: 1),
                  itemBuilder: (context, index) {
                    return Image.network(
                      imageUrls[index],
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: LoadingScreen(
                            messages: [
                              "We are here...",
                              "Almost there...",
                              "Hang tight...",
                            ],
                            progressColor: Colors.blue,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.error));
                      },
                    );
                  },
                ),
              ),
            ),

          // Keep padding for content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post["name"] ?? "",
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.post["info"] ?? "",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 12),
                if (title != null)
                  Text(
                    title,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (highlight != null) const SizedBox(height: 8),
                if (highlight != null)
                  Text(
                    highlight,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                if (body != null) const SizedBox(height: 8),
                if (body != null)
                  Text(
                    body,
                    style: GoogleFonts.cormorantGaramond(fontSize: 18),
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
