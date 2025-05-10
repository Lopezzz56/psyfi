import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:psy_fi/auth/auth_controller.dart';
import 'package:psy_fi/core/components/custom_text_field.dart';
import 'package:psy_fi/core/theme/fonts.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String username; // Add username parameter
  final String phone; // Add phone parameter
  final bool isSignup; // Added this to differentiate between signup and login
  const OtpScreen({super.key, required this.email, required this.username, required this.phone, required this.isSignup});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
@override
void initState() {
  super.initState();

  // Set initial values if it's a signup
  if (widget.isSignup) {
    _usernameController.text = widget.username;
    _phoneController.text = widget.phone;
     print("Pre-filling username: ${_usernameController.text}");
    print("Pre-filling phone: ${_phoneController.text}");
  }
}
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
                'Enter the OTP',
                style: AFonts.subheading,
                textAlign: TextAlign.center,
              ),
           
              const SizedBox(height: 25),
              // Show username and phone fields only for signup
                       if (widget.isSignup) ...[
              CustomTextField(
                label: "Username",
                controller: _usernameController,
                    readOnly: true, // <-- Make username read-only

              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: "Phone",
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                readOnly: true,
              ),
              const SizedBox(height: 16),
            ],
               const SizedBox(height: 25),
              SizedBox(
                height: 56,
                width: 337,
                child: CustomTextField(
                  label: 'OTP',
                  controller: _otpController,
                  obscureText: false,
                   readOnly: false,
                ),
              ),
              const SizedBox(height: 37),
             Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: SizedBox(
    height: 56,
    width: 337,
    child: ElevatedButton(
  onPressed: authController.isLoading
      ? null
      : () {
          authController.verifyOtpAndSaveUser(
            email: widget.email,
            otp: _otpController.text.trim(),
            username: widget.username,
            phone: widget.phone,
            context: context,
          );
        },
  child: authController.isLoading
      ? CircularProgressIndicator()
      : Text("Verify OTP"),
),

  ),
),

              if (authController.errorMessageSafe.isNotEmpty)
                Text(authController.errorMessageSafe, style: AFonts.subheading),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
