import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class AIRepository {
  WebSocketChannel? _channel;
  // final _serverUrl = "ws://10.0.2.2:8000/ws";  // Server URL
  final _serverUrl = "wss://right-beloved-oarfish.ngrok-free.app/ws";
  late Stream<String> _messageStream;

  // Connect to WebSocket
  void connect() {
    if (_channel != null) return;  // Prevent creating a new connection if already connected.

    print("🌐 Connecting to $_serverUrl...");
    _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));

    // Initialize the message stream as a broadcast stream
    _messageStream = _channel!.stream.map((event) => event.toString()).asBroadcastStream();
  }

  // Get the stream that can be listened to multiple times
  Stream<String> get messages => _messageStream;

  // Send message to WebSocket
  void sendMessage(String prompt) {
    print("➡️ Sending to server: $prompt");
    _channel?.sink.add(prompt);
  }

Future<String?> sendMessageAndWaitForResponse(String message) async {
  if (_channel == null) return null;

  final completer = Completer<String?>();

  _channel!.sink.add(jsonEncode({'prompt': message}));

  // Listen for one response only
  _channel!.stream.listen((response) {
    completer.complete(response);
  }, onError: (error) {
    completer.completeError(error);
  });

  return completer.future;
}


  // Disconnect the WebSocket
  void disconnect() {
    _channel?.sink.close();
  }
}
