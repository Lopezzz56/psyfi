import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'PostCard.dart';

class MotivationScreen extends StatelessWidget {
  const MotivationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

 return Scaffold(
  backgroundColor: Colors.white,
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.only(top: 16, left: 8, right: 8, bottom: 80), // 80 for bottom nav
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Posts",
            style: GoogleFonts.cormorantGaramond(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('motivations')
                  .stream(primaryKey: ['id'])
                  .order('created_at')
                  .map((data) => data.map((e) => e).toList()),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final posts = snapshot.data!;
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) => PostCard(post: posts[index]),
                );
              },
            ),
          ),
        ],
      ),
    ),
  ),
);

  }
}
