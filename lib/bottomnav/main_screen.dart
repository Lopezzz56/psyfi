import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:psy_fi/core/components/custom_button.dart';
import 'package:psy_fi/core/components/wifichecker_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class MainScreen extends StatefulWidget {
  final Widget child;
  const MainScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // final List<String> _routes = ['/home', '/aichat', '', '/chat', '/profile'];
  final List<String> _routes = ['/home', '/aichat', '/motivations', '/chat', '/profile'];

  void _onTap(int index) {
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // important for full height control
      backgroundColor: Colors.transparent, // transparent outer layer
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder:
              (_, controller) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Stack(
                  children: [
                    ListView(
                      controller: controller,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      children: [
                        // Welcome Text
                        Text(
                          'Welcome to PsyFy',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 16),

                        // Description Text
                        Text(
                          'PsyFy your trusted psychiatric\n'
                          'companion, empowering you to seek help face challenges and prioritize your well being with confidence\n',
                          // 'Through AI-driven chatbot assistance, supportive community connections, '
                          // 'and expert professional guidance, PsyFy creates a secure space for users to '
                          // 'navigate personal, mental, and health struggles.'
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.justify,
                        ),

                        SizedBox(height: 20),

                        // Call to Action (Optional for better engagement)
                        CustomButton(
                          onPressed: () {
                  Navigator.pop(context);                             },
                          text: 'Start Your Journey',
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 8,
                      right: 12,
                      child: Text(
                        '-f',
                        style: GoogleFonts.dancingScript(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WifiAutoChecker(
      child: Scaffold(
        key: _scaffoldKey,
        extendBody: true,
        resizeToAvoidBottomInset: true,

        body: Stack(
          children: [
            // Main content
            widget.child,

            // Custom bottom nav bar
            Positioned(
              bottom: 7,
              left: 7,
              right: 7,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: _onTap,
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    selectedItemColor: Colors.blueAccent,
                    unselectedItemColor: const Color.fromARGB(255, 52, 52, 52),
                    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: "Home",
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.chat),
                        label: "Ai chat",
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.psychology_outlined),
                        label: "Posts",
                      ),

                      BottomNavigationBarItem(
                        icon: Icon(Icons.forum),
                        label: "Chat",
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person),
                        label: "Profile",
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Branding floating icon ABOVE everything
            // Positioned(
            //   bottom: 25, // Lifted above the nav bar
            //   left: MediaQuery.of(context).size.width / 2 - 30,
            //   child: GestureDetector(
            //     onTap: _showBottomSheet,
            //     child: Container(
            //       height: 70,
            //       width: 70,
            //       decoration: BoxDecoration(
            //         shape: BoxShape.circle,
            //         color: Colors.blueAccent,
            //         boxShadow: [
            //           BoxShadow(
            //             color: Colors.blueAccent.withAlpha(60),
            //             blurRadius: 16,
            //             spreadRadius: 6,
            //           ),
            //         ],
            //       ),
            //       child: ClipOval(
            //         child: Image.asset(
            //           'assets/images/psyfyimg.png',
            //           fit: BoxFit.cover,
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
