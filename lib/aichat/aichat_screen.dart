import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:psy_fi/aichat/aichat_controller.dart';
import 'package:psy_fi/aichat/aichat_repo.dart';
import 'package:psy_fi/chat/repos/chat_repo.dart';
import 'package:psy_fi/chat/screens/chat_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class AIChatScreen extends StatefulWidget {
  final String userId;
  final String userRole;
  final SupabaseClient supabase;

  const AIChatScreen({
    super.key,
    required this.userId,
    required this.userRole,
    required this.supabase,
  });
    @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  late AIController _controller;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = AIController(AIRepository());
  }

  @override
  void dispose() {
    _controller.disposeController();
    _inputController.dispose();
    super.dispose();
  }
   @override
Widget build(BuildContext context) {
  return ChangeNotifierProvider<AIController>(
    create: (_) => _controller,
    child: Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
  padding: EdgeInsets.only(bottom: 70), // height of nav + float button area
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensures proper spacing
              children: [
                Text(
          "🧠 AI Chat",
          style: GoogleFonts.cormorantGaramond(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
                ),
                Text(
          "-f",
          style: GoogleFonts.dancingScript(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade600,
          ),
                ),
              ],
            ),
          ),
              const SizedBox(height: 16),
          
              // Chat messages
              Expanded(
                child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Consumer<AIController>(
                    builder: (context, controller, _) => ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      // reverse: true,
                      itemCount: controller.messages.length,
                      itemBuilder: (_, i) {
                        final msg = controller.messages[i];
                        return Align(
                          alignment: msg.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: msg.isUser
                                  ? Colors.blue[200]
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: buildMessageBubble(
                            context,
                            msg.text,
                            userId: widget.userId,
                            userRole: widget.userRole,
                            supabase: widget.supabase,
                          ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          
              // Input field
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4), // minimal bottom space
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: "Ask something...",
                          hintStyle: GoogleFonts.cormorantGaramond(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                         
                          filled: true,
                          isDense: true, // Reduces height
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Colors.blueAccent,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blueAccent),
          onPressed: () {
            if (_inputController.text.trim().isNotEmpty) {
              _controller.sendMessage(_inputController.text.trim());
              _inputController.clear();
          
              // Scroll to bottom after the next frame
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
                }
              });
            }
          }
          
                    ),
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


Widget buildMessageBubble(
  BuildContext context,
  String message, {
  required String userId,
  required String userRole,
  required SupabaseClient supabase,
}) {

  final messageTextStyle = GoogleFonts.cormorantGaramond(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  if (message.contains('[Talk to a mental health professional 💬]')) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.replaceAll('[Talk to a mental health professional 💬]', ''),
          style: messageTextStyle,
        ),
        const SizedBox(height: 8),
       ElevatedButton(
  onPressed: () {
    context.push('/chat');
  },
  child: Text("Talk to a mental health professional 💬"),
),


      ],
    );
  } else if (message.contains('[Show helpline contacts]')) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.replaceAll('[Show helpline contacts]', ''),
          style: messageTextStyle,
        ),
        const SizedBox(height: 8),
        Text("📞 Substance Abuse and Mental Health Services Administration (SAMHSA): 1-800-662-HELP (4357)", style: messageTextStyle),
        Text("📞 NHS 111 (UK): Call 111 and select the mental health option", style: messageTextStyle),
        Text("🏥 Your GP can help connect you to the right support.", style: messageTextStyle),
      ],
    );
  }

  // Regular message
  return Text(message, style: messageTextStyle);
}

}
