import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:psy_fi/chat/repos/chatdetail_repo.dart';
import 'package:psy_fi/core/components/encrypt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatDetailController extends ChangeNotifier {
  final ChatDetailRepository repo;
  final SupabaseClient supabase;
  final String currentUserId;
  final String peerId;

  List<Map<String, dynamic>> messages = [];
  bool isTyping = false;
  bool loading = false;
  String? error;
  bool isConnected = true;
  bool get sendDisabled => !isConnected || error != null;

  RealtimeChannel? _channel;
StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  ChatDetailController({
    required this.repo,
    required this.supabase,
    required this.currentUserId,
    required this.peerId,
  }) {
    _initConnectivity();
  }

void _initConnectivity() {
  _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
    final wasConnected = isConnected;
    isConnected = result != ConnectivityResult.none;

    if (!wasConnected && isConnected) {
      fetchMessages(); // Retry on reconnect
    }

    notifyListeners();
  });
}

void listenToMessages() {
  fetchMessages();

  _channel = supabase.channel('chat-$currentUserId-$peerId');

  _channel!
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        callback: (payload) {
          final newMsg = payload.newRecord;

          final isBetween =
              (newMsg['sender_id'] == currentUserId && newMsg['receiver_id'] == peerId) ||
              (newMsg['sender_id'] == peerId && newMsg['receiver_id'] == currentUserId);

          if (isBetween) {
            // ✅ Decrypt message text
            try {
              newMsg['message'] = MessageCryptoHelper.decryptText(newMsg['message']);
            } catch (_) {
              newMsg['message'] = '[Decryption Failed]';
            }

            messages.insert(0, newMsg);

            if (newMsg['is_typing'] == true && newMsg['sender_id'] == peerId) {
              isTyping = true;
              notifyListeners();
              Future.delayed(const Duration(seconds: 2), () {
                isTyping = false;
                notifyListeners();
              });
            } else {
              notifyListeners();
            }
          }
        },
      )
      .subscribe();
}


  Future<void> fetchMessages() async {
    loading = true;
    notifyListeners();
    try {
      final result = await repo.fetchMessages(currentUserId, peerId);
      messages = result;
      error = null;
    } catch (e) {
      error = 'Failed to load messages: $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

Future<void> sendMessage(String text, {String? imageUrl}) async {
  try {
    await repo.sendMessage(currentUserId, peerId, text, imageUrl: imageUrl);


    notifyListeners();
  } catch (e) {
    error = 'Failed to send message: $e';
    notifyListeners();
  }
}


  Future<void> markSeen() async {
    try {
      await repo.markMessagesAsSeen(currentUserId, peerId);
    } catch (e, stackTrace) {
      error = '❌ Failed to mark messages as seen: $e';
      print('$error\n$stackTrace');
      notifyListeners();
    }
  }

  Future<void> setTyping(bool typing) async {
    try {
      await repo.updateTypingStatus(currentUserId, peerId, typing);
    } catch (e, stackTrace) {
      print('❌ Error in setTyping: $e\n$stackTrace');
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _connectivitySub?.cancel();
    super.dispose();
  }
}
