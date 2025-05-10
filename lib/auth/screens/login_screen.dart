import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:psy_fi/auth/auth_controller.dart';
import 'package:psy_fi/auth/screens/otp_screen.dart';
import 'package:psy_fi/auth/screens/signup_screen.dart';
import 'package:psy_fi/core/components/custom_text_field.dart';
import 'package:psy_fi/core/theme/fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
   final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
        final authController = Provider.of<AuthController>(context);

    return Scaffold(
      body: Stack(
        children: [
          //  RibbonAnimationBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                children: [
                  const SizedBox(height: 150),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        color: Colors.transparent,
                        child: Image.asset(
                          'assets/images/lock.png',
                          height: 120,
                          width: 120,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 64),
                  Text(
                    'Welcome Back You have been missed!',
                    style: AFonts.subheading,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    height: 56,
                    width: 337,
                    child: CustomTextField(
                    label: 'Email',
                    controller: _emailController,
                    obscureText: false,
                    readOnly: false,
                    //icon: Icons.lock, // Optional
                    ),
                  ),
                  const SizedBox(height: 25),
                  // SizedBox(
                  //   height: 56,
                  //   width: 337,
                  //   child: CustomTextField(
                  //   label: 'Password',
                  //   controller: null,
                  //  //  _passwordController,
                  //   obscureText: true,
                  //   //icon: Icons.lock, // Optional
                  //   ),
                  // ),
                  const SizedBox(height: 37),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 56,
                      width: 337,
                      child: ElevatedButton(
  onPressed: authController.isLoading
      ? null
      : () async {
          // Send OTP
          await authController.sendOtp(
            email: _emailController.text.trim(),
          );

          if (authController.isOtpSent) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtpScreen(
                  email: _emailController.text.trim(),
                  isSignup: false,  // Set isSignup to false for login
                  username: '',     // Empty username for login
                  phone: '',        // Empty phone for login
                ),
              ),
            );
          }
        },
  child: authController.isLoading
      ? const CircularProgressIndicator()
      : const Text("Send OTP"),
),
          
                   ),
                   ),
           if (authController.errorMessageSafe.isNotEmpty)
            Text(authController.errorMessageSafe, style: AFonts.subheading),
                    
                   
                  
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Align(
                      alignment: Alignment.center,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Not Registered? ',
                              style: AFonts.body,
                            ),
                            TextSpan(
                              text: 'Sign up',
                              style: AFonts.caption,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const SignupScreen()),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}