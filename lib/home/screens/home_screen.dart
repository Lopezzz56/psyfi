import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:psy_fi/core/components/animated_arrow.dart';
import 'package:go_router/go_router.dart';
import 'package:psy_fi/core/components/loading_screen.dart';
import 'package:psy_fi/home/controllers/home_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>   with SingleTickerProviderStateMixin{
    late List<Map<String, String>> tasks;
late List<String> imageUrls = [];

  // AnimationController? _controller;
  // Animation<Offset>? _arrowAnimation;
  // final List<String> imageUrls = [
  //   'https://www.shihoriobata.com/wp-content/uploads/2020/07/one-day-at-a-time-878x1024.jpg',
  //   'https://i.pinimg.com/736x/64/21/65/642165bec9bfb3738cae1684e48379a9.jpg',
  //   'https://www.shihoriobata.com/wp-content/uploads/2020/07/search-for-soul-in-everything-878x1024.jpg',
  //   // 'https://picsum.photos/id/238/400/300',
  //   // 'https://picsum.photos/id/239/400/300',
  //   // 'https://picsum.photos/id/238/900/600',
  //   // 'https://picsum.photos/id/239/900/600',
  // ];

String greeting = '';


  @override
  void initState() {
    super.initState();
      tasks = [
      // {'title': 'Grounding', 'route': '/grounding-info'},
      {'title': 'Meditation', 'route': '/breathing-info'},
      {'title': 'Calming Audio', 'route': '/calming-info'},
    ];
     _updateGreeting();  // Update the greeting when the widget is initialized
     
  // Save FCM token after build context is ready
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final user = Supabase.instance.client.auth.currentUser;
        final controller = Provider.of<HomeScreenController>(context, listen: false);

    if (user != null) {
      final controller = Provider.of<HomeScreenController>(context, listen: false);
      controller.saveFcmToken(user.id);
    }
    final fetchedImages = await controller.fetchBucketImages();
    if (fetchedImages.isNotEmpty) {
      setState(() {
        imageUrls.clear();
        imageUrls.addAll(fetchedImages);
      });
    }
  });
  
  }

  // @override
  // void dispose() {
  //   _controller?.dispose();
  //   super.dispose();
  // }


  List<Widget> get taskWidgets {
    List<Widget> widgets = [];
    for (final task in tasks) {
      widgets.add(
        Padding(
          padding: EdgeInsets.all(16),
          child: GestureDetector(
onTap: () => context.push(task['route']!),  // PUSH not GO
            child: Container(
              height: 100,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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

              child: Center(
                child: Text(
                  task['title']!,
                   style: GoogleFonts.cormorantGaramond(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
                ),
              ),
            ),
          ),
        ),
      );
      if (task != tasks.last) {
        widgets.add(
          AnimatedArrow(),
        );
      }
    }
    return widgets;
  }
  // Method to update the greeting based on the time
  void _updateGreeting() {
    final hour = DateTime.now().hour;
    String newGreeting;

    if (hour < 12) {
      newGreeting = 'Morning . . .';
    } else if (hour < 18) {
      newGreeting = 'Afternoon . . .';
    } else {
      newGreeting = 'Night . . .';
    }

    setState(() {
      greeting = newGreeting;  // Update the greeting to trigger a UI rebuild
    });
  }



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and some vertical space
           Padding(
                padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                child: Text(
                  greeting,
                   style: GoogleFonts.cormorantGaramond(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                ),
              ),
              // Full-width swipeable images
              SizedBox(
                height: 280,
                child: PageView.builder(
                  itemCount: imageUrls.length,
                  controller: PageController(viewportFraction: 1),
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                             color: Colors.blueAccent.withAlpha((0.15 * 255).round()), // 15% opaque gray
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrls[index],
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return  Center(
                              child:  LoadingScreen(
        messages: [
          "We are here...",
          "Almost there...",
          "Hang tight...",
        ],
        progressColor: Colors.blue, // or your theme color
      ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.error));
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),


         Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
              width: double.infinity,  // Full width
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                // borderRadius: BorderRadius.circular(12),
                // border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                // color: Colors.blueGrey.withOpacity(0.05),  // Light background color for contrast
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✨ Anxiety thrives on overthinking—peace thrives on presence ✨',
                    style: TextStyle(
                      fontFamily: 'Cormorant Garamond',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Simple exercises like grounding 🌍 and mindful breathing 🌬️ help shift focus, reduce stress 💆‍♀️, and make seeking support easier 💪. Breathe in 🌱, breathe out 🍃, feel the difference. 🌈',
                    style: TextStyle(
                      fontFamily: 'Cormorant Garamond',
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
              const SizedBox(height: 24),

          const AnimatedArrow(
), // Arrow pointing to Grounding
    ...taskWidgets, // Your dynamic task list
              const SizedBox(height: 100),
          
              // Add more widgets below as needed
            ],
          ),
        ),
      ),
    );
  }
}
