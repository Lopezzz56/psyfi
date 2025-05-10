import 'package:flutter/material.dart';
import 'package:psy_fi/home/repos/grounding_repo.dart';
class GroundingController extends ChangeNotifier {
  final GroundingRepository _repository;
  List<Message> messages = [];
  bool serverAvailable = false;
  bool isLoading = false;
  bool connectionClosed = false; // Add this line to track connection status

  GroundingController(this._repository);

  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    await checkServer();
    if (serverAvailable) {
      _repository.connect();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> checkServer() async {
    try {
      serverAvailable = await _repository.checkServerAvailable();
    } catch (e) {
      serverAvailable = false;
      print('Error checking server: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<String?> sendMessage(String prompt) async {
    isLoading = true;
    connectionClosed = false;

    notifyListeners(); // This triggers the UI to update and show the loading screen

    try {
      final wrappedPrompt = "You are a kind and supportive psychology assistant. User: $prompt";
      final response = await _repository.sendMessageAndWaitForResponse(wrappedPrompt);

      isLoading = false;
      notifyListeners(); // Hide the loading screen when response is received

      return response;
    } catch (e) {
      debugPrint("❌ Error sending message: $e");

      isLoading = false;
      connectionClosed = true; // Mark connection as closed in case of error

      notifyListeners(); // Hide the loading screen in case of error

      return null;
    }
  }

  void disposeController() {
    _repository.disconnect();
    super.dispose();
  }

  @override
  void dispose() {
    _repository.disconnect();
    super.dispose();
  }
}


class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}
