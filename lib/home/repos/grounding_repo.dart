import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class GroundingRepository {
  WebSocketChannel? _channel;
  final String _serverUrl = "wss://right-beloved-oarfish.ngrok-free.app/ws";
  late StreamController<String> _messageStreamController;
  bool _connected = false;

  GroundingRepository() {
    _messageStreamController = StreamController<String>.broadcast();
  }

  void connect() {
    if (_connected) return;
    try {
      print("🌐 Connecting to $_serverUrl...");
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      _connected = true;

      _channel!.stream.listen(
        (event) {
          print("📩 Message received: $event");
          _messageStreamController.add(event);
        },
        onDone: () {
          print("🔌 Connection closed by server.");
          disconnect();
        },
        onError: (error) {
          print("⚡ WebSocket error: $error");
          disconnect();
        },
      );
    } catch (e) {
      print('🔴 Error connecting: $e');
      disconnect();
    }
  }

  bool isConnected() => _connected;

  Stream<String> get messages => _messageStreamController.stream;

  void sendPrompt(String prompt) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({'prompt': prompt}));
    }
  }

 Future<String?> sendMessageAndWaitForResponse(String message, {Duration timeout = const Duration(seconds: 70)}) async {
  if (_channel == null || !_connected) {
    print("❌ Not connected.");
    return null;
  }

  final completer = Completer<String?>(); // 🔧 make this nullable
  late StreamSubscription subscription;

  // Listen for the next message only
  subscription = _messageStreamController.stream.listen((response) {
    if (!completer.isCompleted) {
      completer.complete(response);
      subscription.cancel();
    }
  }, onError: (error) {
    if (!completer.isCompleted) {
      completer.completeError(error);
    }
    subscription.cancel();
  });

  // Send the message
  _channel!.sink.add(jsonEncode({'prompt': message}));

  // Timeout handler
  return completer.future.timeout(timeout, onTimeout: () {
    subscription.cancel();
    print("⏰ Timeout waiting for response.");
    return null; // ✅ now valid
  });
}



  Future<bool> checkServerAvailable() async {
    try {
      print('🔵 [GroundingRepo] Trying to connect...');
      final testChannel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      final completer = Completer<bool>();
      late final StreamSubscription subscription;

      subscription = testChannel.stream.listen(
        (_) {
          if (!completer.isCompleted) {
            print('🟢 [GroundingRepo] Connected successfully.');
            completer.complete(true);
          }
          subscription.cancel();
          testChannel.sink.close();
        },
        onError: (error) {
          print('🔴 [GroundingRepo] Connection error: $error');
          if (!completer.isCompleted) {
            completer.complete(false);
          }
          subscription.cancel();
          testChannel.sink.close();
        },
      );

      // Timeout safeguard
      Future.delayed(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          print('🟡 [GroundingRepo] Connection timed out.');
          completer.complete(false);
          subscription.cancel();
          testChannel.sink.close();
        }
      });

      return completer.future;
    } catch (e) {
      print('🔴 [GroundingRepo] Exception during server check: $e');
      return false;
    }
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _connected = false;
    print("🔌 Disconnected.");
  }
}
