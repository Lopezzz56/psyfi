import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:psy_fi/auth/auth_controller.dart';
import 'package:psy_fi/auth/screens/login_screen.dart';
import 'package:psy_fi/auth/screens/otp_screen.dart';
import 'package:psy_fi/core/components/custom_text_field.dart';
import 'package:psy_fi/core/theme/fonts.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  // final TextEditingController _passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
        final authController = Provider.of<AuthController>(context);

    return Scaffold(
      body: Center(
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
                'Let’s Create an Account',
                style: AFonts.subheading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              // _buildTextField(_usernameController, 'Username'),
              SizedBox(
                height: 56,
                width: 337,
                child: CustomTextField(
                  label: 'Username',
                  controller: _usernameController,
                  obscureText: false,
                  readOnly: false,
                  //icon: Icons.lock, // Optional
                ),
              ),
              const SizedBox(height: 25),
              // _buildTextField(_emailController, 'Email'),
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
              // _buildTextField(_phoneController, 'Number'),
              SizedBox(
                height: 56,
                width: 337,
                child: CustomTextField(
                  label: 'Number',
                  controller: _phoneController,
                  obscureText: false,
                  readOnly: false,
                  //icon: Icons.lock, // Optional
                ),
              ),
              const SizedBox(height: 25),
              // _buildTextField(_passwordController, 'Password', isPassword: true),
              // SizedBox(
              //   height: 56,
              //   width: 337,
              //   child: CustomTextField(
              //     label: 'Password',
              //     controller: _passwordController,
              //     obscureText: true,
              //     //icon: Icons.lock, // Optional
              //   ),
              // ),
              const SizedBox(height: 37),
             Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Column( // Use a Column to stack widgets properly
    crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
    children: [
      SizedBox(
        height: 56,
        width: 337,
        child: ElevatedButton(
onPressed: authController.isLoading
    ? null
    : () async {
        final username = _usernameController.text.trim();
        final email = _emailController.text.trim();
        final phone = _phoneController.text.trim();

        if (username.isEmpty || phone.isEmpty) {
          authController.setError("Username and phone number cannot be empty.");
          return;
        }

        await authController.sendOtpForSignup(
          email: email,
          username: username,
          phone: phone,
          context: context,
        );

        if (authController.isOtpSent) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(
                email: email,
                username: username,
                phone: phone,
                isSignup: true,
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
      const SizedBox(height: 8), // Provide proper spacing
    if (authController.errorMessageSafe.isNotEmpty)
  Text(authController.errorMessageSafe, style: AFonts.subheading),
      const SizedBox(height: 20), // Extra spacing
    ],
  ),
),
            const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Align(
                  alignment: Alignment.center,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Already Registered? ',
                          style: AFonts.body,
                        ),
                        TextSpan(
                          text: 'Log IN',
                          style: AFonts.caption,
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
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
    );
  }
}
