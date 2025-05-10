import 'dart:ui';

import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreenRepository {
  final SupabaseClient client;
 RealtimeChannel? _messageChannel;
  ChatScreenRepository(this.client);

  void subscribeToMessages({
    required String currentUserId,
    required VoidCallback onNewMessage,
  }) {
    _messageChannel = client
        .channel('public:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final newMessage = payload.newRecord;
            if (newMessage['receiver_id'] == currentUserId) {
              onNewMessage();
            }
          },
        )
        .subscribe();
  }

  void unsubscribeFromMessages() {
    if (_messageChannel != null) {
      client.removeChannel(_messageChannel!);
      _messageChannel = null;
    }
  }
  /// Fetches chat data: user profile, last message, and unseen message count.
  Future<List<Map<String, dynamic>>> fetchChatUsersWithMetadata(
    String currentUserId, {
    String? roleFilter, // Optional: filter by role
  }) async {
    try {
      // Step 1: Fetch all users except current user
      final userQuery = client
          .from('users')
          .select('id, username, email, image_icon, role')
          .neq('id', currentUserId);

      if (roleFilter != null) {
        userQuery.eq('role', roleFilter);
      }

      final List<Map<String, dynamic>> users = await userQuery;

      // Step 2: Fetch all messages involving current user
      final List<Map<String, dynamic>> messages = await client
          .from('messages')
          .select('sender_id, receiver_id, message, created_at, is_seen')
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .order('created_at', ascending: false);

      // Step 3: Process messages per other user
      final Map<String, Map<String, dynamic>> messageMap = {};

      for (final msg in messages) {
        final senderId = msg['sender_id'];
        final receiverId = msg['receiver_id'];
        final isSender = senderId == currentUserId;
        final otherUserId = isSender ? receiverId : senderId;

        if (otherUserId == null || otherUserId == currentUserId) continue;

        // Initialize if not exists
        messageMap.putIfAbsent(otherUserId, () => {
              'lastMessage': '',
              'createdAt': '',
              'unseenCount': 0,
            });

        // Last message logic (first encountered in descending list)
        if (messageMap[otherUserId]!['lastMessage'] == '') {
          messageMap[otherUserId]!['lastMessage'] = msg['message'];
          messageMap[otherUserId]!['createdAt'] = msg['created_at'];
        }

        // Unseen count logic
if (!isSender && msg['is_seen'] == false && receiverId == currentUserId) {
  messageMap[otherUserId]!['unseenCount'] += 1;
}

      }

      // Step 4: Combine with user profiles
      final List<Map<String, dynamic>> chatList = [];

      for (final user in users) {
        final userId = user['id'];
        final msgMeta = messageMap[userId];


        chatList.add({
          'user': user,
          'lastMessage': msgMeta?['lastMessage'] ?? '',
          'createdAt': msgMeta?['createdAt'],
          'unseenCount': msgMeta?['unseenCount'] ?? 0,
        });
      }
// ✅ Now sort AFTER the list is built
chatList.sort((a, b) {
  final aTime = a['createdAt'];
  final bTime = b['createdAt'];
  if (aTime == null) return 1;
  if (bTime == null) return -1;
  return DateTime.parse(bTime).compareTo(DateTime.parse(aTime));
});
      return chatList;
    } catch (e) {
      throw Exception('Failed to fetch chat data: $e');
    }
  }

  /// Real-time typing status stream
  Stream<bool> subscribeTypingStatus(String senderId, String receiverId) {
    return client.from('typing_status').stream(primaryKey: ['id']).map((event) {
      final filtered = event.where(
        (row) =>
            row['sender_id'] == senderId && row['receiver_id'] == receiverId,
      );
      if (filtered.isEmpty) return false;
      return filtered.first['is_typing'] ?? false;
    });
  }

  /// Set typing status (insert or update)
  Future<void> setTypingStatus(
    String senderId,
    String receiverId,
    bool isTyping,
  ) async {
    final existing = await client
        .from('typing_status')
        .select()
        .eq('sender_id', senderId)
        .eq('receiver_id', receiverId)
        .maybeSingle();

    if (existing != null) {
      await client
          .from('typing_status')
          .update({
            'is_typing': isTyping,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', existing['id']);
    } else {
      await client.from('typing_status').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'is_typing': isTyping,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }
}
