import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:psy_fi/core/components/custom_button.dart';
import 'package:psy_fi/core/components/global_state.dart';
import 'package:psy_fi/core/components/loading_screen.dart';
import 'package:psy_fi/core/components/wifichecker_screen.dart';
import 'package:psy_fi/profile/profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
      // Fetch user data when screen loads
    Future.microtask(() {
      final profileController = Provider.of<ProfileController>(context, listen: false);
      final globalState = Provider.of<GlobalState>(context, listen: false);

      profileController.fetchUserDetails(globalState);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileController = Provider.of<ProfileController>(context);
final global = Provider.of<GlobalState>(context);
  
  if (global.userId == null) {
    return const Center(child: Text("No user logged in"));
  }

    return WifiAutoChecker(
      child: Scaffold(
        backgroundColor: Colors.white,
     body: profileController.isLoading
    ?  Center(child:  LoadingScreen(
        messages: [
          "We are here...",
          "Almost there...",
          "Hang tight...",
        ],
        progressColor: Colors.blue, // or your theme color
      ))
    : SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                    // Custom Title
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Text(
          "Profile",
          style: GoogleFonts.cormorantGaramond(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.38,
                  child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blueAccent.withAlpha((0.15 * 255).round()),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withAlpha((0.07 * 255).round()),
                        blurRadius: 14,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.08,
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            colors: [
                Colors.blue.shade700,
                Colors.blueAccent.shade400,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds);
                        },
                        child: Text(
                          'PSY FY',
                          style: GoogleFonts.kenia(
                            fontSize: 120,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildInfoBox("Username:", profileController.username),
                    const SizedBox(height: 16),
                    _buildInfoBox("Email:", profileController.email),
                    const SizedBox(height: 16),
                    _buildInfoBox("Phone No:", profileController.phone),
                    const SizedBox(height: 20),
CustomButton(
  text: 'Sign Out', // required even if unused
  onPressed: () => profileController.signOut(context),
  // color: Colors.redAccent,
  
),


                    const SizedBox(height: 82),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      ),
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color:  Colors.white,
        borderRadius: BorderRadius.circular(8),
          border: Border.all(
    color: Colors.blueAccent.withAlpha((0.15 * 255).round()), // 15% opaque gray
    width: 1,
  ),
  boxShadow: [
    BoxShadow(
      color: Colors.blueAccent.withAlpha((0.07 * 255).round()), // 7% opaque black
      blurRadius: 14,
      spreadRadius: 2,
      offset: const Offset(0, 6),
    ),
  ],
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            color: Colors.black87,
          ),
          children: [
            TextSpan(
              text: "$label ",
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
