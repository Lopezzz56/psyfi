import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:psy_fi/core/components/custom_button.dart';
import 'package:psy_fi/core/components/loading_screen.dart';
import 'package:psy_fi/home/controllers/grounding_controller.dart';
import 'package:psy_fi/home/repos/grounding_repo.dart';
import 'package:psy_fi/home/screens/grounding/feedback_screen.dart';

class GroundingFormScreen extends StatefulWidget {
  const GroundingFormScreen({super.key});

  @override
  State<GroundingFormScreen> createState() => _GroundingFormScreenState();
}

class _GroundingFormScreenState extends State<GroundingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _responseController = TextEditingController();
  
  final List<String> questions = [
    '5 Things You Can See',
    '4 Things You Can Feel',
    '3 Things You Can Hear',
    '2 Things You Can Smell',
    '1 Thing You Can Taste'
  ];

  late GroundingController _controller;
  List<String> responses = [];
  int currentQuestionIndex = 0;
  bool _isRetrying = false;
  bool _checkingServer = true;
  bool _isLoading = false;
  bool _isSubmitting = false;
  @override
  void initState() {
    super.initState();
    final repo = GroundingRepository();
    _controller = GroundingController(repo);
    _initialize();
  }

  Future<void> _initialize() async {
    await _controller.init();
    await _checkServerAvailability();
  }

  Future<void> _checkServerAvailability() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _checkingServer = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _responseController.dispose();
    super.dispose();
  }

void _submitForm() async {
  if (_formKey.currentState!.validate()) {
    responses.add(_responseController.text.trim());

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        _responseController.clear();
      });
    } else {
      setState(() => _isSubmitting = true); // Start loading
      await _sendDataToAI();
      if (mounted) setState(() => _isSubmitting = false); // Stop loading
    }
  }
}



Future<void> _sendDataToAI() async {
  if (_checkingServer || _isLoading) return;

  if (!_controller.serverAvailable) {
    _showErrorDialog();
    return;
  }

  setState(() => _isLoading = true);

  String prompt = '''
I'm guiding a user through a 5-4-3-2-1 grounding exercise. Here are their reflections:
- See: ${responses[0]}
- Feel: ${responses[1]}
- Hear: ${responses[2]}
- Smell: ${responses[3]}
- Taste: ${responses[4]}

Could you provide supportive, constructive feedback or insights to help them deepen or reflect on their grounding experience?
  ''';

  bool timedOut = false;
  dynamic feedback;

  try {
    feedback = await Future.any([
      _controller.sendMessage(prompt),
      Future.delayed(const Duration(seconds: 90), () {
        timedOut = true;
        return null;
      }),
    ]);
  } catch (e) {
    print('Error sending message: $e');
    feedback = null;
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }

  if (!mounted) return;

  if (timedOut) {
    _showErrorDialog(message: 'The request timed out. Please try again.');
    return;
  }

  if (_controller.connectionClosed || feedback == null) {
    _showErrorDialog();
    return;
  }

  await Future.delayed(const Duration(milliseconds: 100));
  if (mounted) context.go('/feedback', extra: feedback);
}

// Future<void> _sendDataToAI() async {
//   if (_checkingServer) return;

//   if (!_controller.serverAvailable) {
//     _showErrorDialog();
//     return;
//   }

//   String prompt = '''
//   I am conducting a grounding exercise using the 5-4-3-2-1 technique.
//   The responses collected are:
//   1. Things I can see: ${responses[0]}
//   2. Things I can feel: ${responses[1]}
//   3. Things I can hear: ${responses[2]}
//   4. Things I can smell: ${responses[3]}
//   5. Things I can taste: ${responses[4]}

//   Can you provide feedback on how I can improve the grounding experience based on these responses?
//   '''; 

//   try {
//     final feedback = await _controller.sendMessage(prompt);

//     if (!mounted) return;

//     if (_controller.connectionClosed) {
//       _showErrorDialog();
//       return;
//     }

//     if (feedback != null) {
//       await Future.delayed(const Duration(milliseconds: 100));
//       if (mounted) {
//         context.go('/feedback', extra: feedback);
//       }
//     } else {
//       _showErrorDialog();
//     }
//   } catch (e) {
//     _showErrorDialog();
//   }
// }

void _showErrorDialog({String message = 'Failed to get a response from AI.'}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24), // Prevents overflow
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Error',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 48, // Responsive max width
            minWidth: 300,
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
        actions: [
          _isRetrying
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: LoadingScreen(
                    messages: [
                      "We are here...",
                      "Almost there...",
                      "Hang tight...",
                    ],
                    progressColor: Colors.blue,
                  ),
                )
              : CustomButton(
                  text: 'Retry',
                  onPressed: _retryConnection,
                ),
        ],
      );
    },
  );
}


  Future<void> _retryConnection() async {
    setState(() {
      _isRetrying = true;
    });

    await _controller.init();

    if (!mounted) return;

    setState(() {
      _isRetrying = false;
    });

    if (_controller.serverAvailable) {
      Navigator.of(context).pop(); // Close the error dialog
      await _sendDataToAI();
    } else {
      _showErrorDialog();
    }
  }

  @override
Widget build(BuildContext context) {
  if (_controller.isLoading) {
  return const LoadingScreen(
    messages: [
      'Sending your message...',
      'Almost there...',
      'We are here for you...',
      'Processing your responses...',
    ],
  );
}

  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Grounding Exercise',
        style: GoogleFonts.cormorantGaramond(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.black),
    ),
    body: _checkingServer
        ? const Center(child: LoadingScreen(
        messages: [
          "We are here...",
          "Almost there...",
          "Hang tight...",
        ],
        progressColor: Colors.blue, // or your theme color
      ))
        : _controller.serverAvailable
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grounding Technique (5-4-3-2-1)',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          questions[currentQuestionIndex],
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _responseController,
                          maxLines: 3,
                          style: GoogleFonts.cormorantGaramond(fontSize: 20),
                          decoration: InputDecoration(
                            labelText: 'Your Response',
                            labelStyle: GoogleFonts.cormorantGaramond(fontSize: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please fill this field';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 40),
CustomButton(
  text: _isSubmitting 
      ? ''  // no text
      : (currentQuestionIndex == questions.length - 1 ? 'Submit' : 'Next'),
  onPressed: _isSubmitting ? null : _submitForm,
  child: _isSubmitting
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
      : null, // fallback to `text`
),


                      ],
                    ),
                  ),
                ),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '⚠️ AI server is not available.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 30),
CustomButton(
  text: 'Retry',
  onPressed: _retryConnection,
),
                    ],
                  ),
                ),
              ),
  );
}

}
