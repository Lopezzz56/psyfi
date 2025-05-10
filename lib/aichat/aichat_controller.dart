import 'dart:async';

import 'package:flutter/material.dart';
import 'package:psy_fi/aichat/aichat_repo.dart';

class AIController extends ChangeNotifier {
  final AIRepository _repo;
  List<ChatMessage> _messages = [];
  Timer? _thinkingTimer;
  int _dotCount = 1;
  List<ChatMessage> get messages => _messages;

  AIController(this._repo) {
    _repo.connect();

    _repo.messages.listen(
      (message) async {
                // Stop thinking timer
        _thinkingTimer?.cancel();
                // Replace the thinking message with the actual response
        _messages.removeWhere((msg) => msg.isThinking);
                // notifyListeners();

        await Future.delayed(Duration(milliseconds: 600));
        _messages.add(ChatMessage(text: message, isUser: false));
        // // 💬 Show "typing..." while AI is preparing a response
        // _messages.add(ChatMessage(text: "...", isUser: false));
        // notifyListeners();

        // await Future.delayed(Duration(milliseconds: 600));

        // Replace the "..." with the actual AI response
        // _messages.removeLast();
        // _messages.add(ChatMessage(text: message, isUser: false));
        notifyListeners();
      },
      onError: (error) {
        _thinkingTimer?.cancel();
        _messages.removeWhere((msg) => msg.isThinking);
        _messages.add(ChatMessage(text: "⚠️ Error: $error", isUser: false));
        notifyListeners();
      },
    );
  }

  void sendMessage(String prompt) {
    if (prompt.trim().isEmpty) return;

    final wrappedPrompt = "You are a kind and supportive psychology assistant. User: $prompt";

    _messages.add(ChatMessage(text: prompt, isUser: true));
    // notifyListeners();
    _messages.add(ChatMessage(text: "Thinking🤔.", isUser: false, isThinking: true));
    notifyListeners();

        _startThinkingAnimation();
    try {
      _repo.sendMessage(wrappedPrompt); // Send the wrapped prompt to the server
    } catch (e) {
           _thinkingTimer?.cancel();
      _messages.removeWhere((msg) => msg.isThinking); 
      _messages.add(ChatMessage(text: "⚠️ Failed to send: $e", isUser: false));
      notifyListeners();
    }
  }
  void _startThinkingAnimation() {
    _thinkingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _dotCount = (_dotCount % 3) + 1;
      final dots = '.' * _dotCount;

      final thinkingIndex = _messages.indexWhere((m) => m.isThinking);
      if (thinkingIndex != -1) {
        _messages[thinkingIndex] = ChatMessage(text: dots, isUser: false, isThinking: true);
        notifyListeners();
      }
    });
  }
  void disposeController() {
    _repo.disconnect();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
final bool isThinking;
ChatMessage({
  required this.text,
  required this.isUser,
  this.isThinking = false,
});
}
