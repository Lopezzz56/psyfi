import 'package:psy_fi/core/components/encrypt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatDetailRepository {
  final SupabaseClient supabase;

  ChatDetailRepository(this.supabase);

  Future<List<Map<String, dynamic>>> fetchMessages(String currentUserId, String peerId) async {
    final result = await supabase
        .from('messages')
        .select()
        .or(
          'and(sender_id.eq.$currentUserId,receiver_id.eq.$peerId),' +
          'and(sender_id.eq.$peerId,receiver_id.eq.$currentUserId)',
        )
        .order('created_at', ascending: false);
    final messages = List<Map<String, dynamic>>.from(result);
      // Decrypt the messages
  for (final msg in messages) {
    try {
      msg['message'] = MessageCryptoHelper.decryptText(msg['message']);
    } catch (_) {
      msg['message'] = '[Decryption Error]';
    }
  }

  return messages;
  }

  Future<void> sendMessage(String senderId, String receiverId, String text, {String? imageUrl}) async {
    final encryptedText = MessageCryptoHelper.encryptText(text);
      print('Original: $text');
  print('Encrypted: $encryptedText');
    await supabase.from('messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': encryptedText,
      if (imageUrl != null) 'image_url': imageUrl,
    });
  }

Future<void> markMessagesAsSeen(String currentUserId, String peerId) async {
  try {
    final updated = await supabase
        .from('messages')
        .update({'is_seen': true})
        .or('and(receiver_id.eq.$currentUserId,sender_id.eq.$peerId,is_seen.eq.false),and(receiver_id.eq.$currentUserId,sender_id.eq.$peerId,is_seen.is.null)')
        .select();

    print('[✅] markMessagesAsSeen → Updated rows: ${updated.length}\n$updated');
  } catch (e, stackTrace) {
    print('🔴 markMessagesAsSeen error: $e\n$stackTrace');
    rethrow;
  }
}



  Future<void> updateTypingStatus(String senderId, String receiverId, bool isTyping) async {
    try {
      await supabase.from('messages').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'is_typing': isTyping,
      });

      print('[✍️] Typing status updated → $isTyping from $senderId to $receiverId');
    } catch (e, stackTrace) {
      print('🔴 updateTypingStatus error: $e\n$stackTrace');
      rethrow;
    }
  }
}