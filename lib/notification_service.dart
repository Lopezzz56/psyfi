import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:psy_fi/core/components/encrypt.dart';
import 'package:psy_fi/core/components/global_state.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class NotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init(BuildContext context) async {
    final settings = await _firebaseMessaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationTap(context, response.payload);
        },
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final data = message.data;
        final notification = message.notification;
 /// Handle motivational messages regardless of other types
  if (data['type'] == 'motivation') {
    final motivationName = data['motivation_name'] ?? 'New Post';

    await showLocalNotification(
      senderName: "Motivation",
      senderImageUrl: null,
      message: motivationName,
    );
    return; // Prevent fallthrough to encrypted chat logic
  }

        if (notification != null && data['sender_id'] != null) {
          final senderName = data['sender_name'] ?? 'Unknown';
          final senderImage = data['sender_image'];
          final msg = notification.body ?? '';
          String decryptedMsg;

          try {
            decryptedMsg = MessageCryptoHelper.decryptText(msg);
          } catch (_) {
            decryptedMsg = '[Decryption Failed]';
          }

          await showLocalNotification(
            senderName: senderName,
            senderImageUrl: senderImage,
            message: decryptedMsg,
          );
        }

      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final data = message.data;
        if (data.containsKey('sender_id')) {
          _navigateToChat(context, data['sender_id']);
        }
      });
    }
  }

  Future<void> showLocalNotification({
    required String senderName,
    required String? senderImageUrl,
    required String message,
  }) async {
    Uint8List? largeIconBytes;

    if (senderImageUrl != null && senderImageUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(senderImageUrl));
        if (response.statusCode == 200) {
          largeIconBytes = response.bodyBytes;
        }
      } catch (_) {
        // Ignore icon loading errors
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'chat_channel_id',
      'Chat Notifications',
      channelDescription: 'Notifications for chat messages',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      largeIcon: largeIconBytes != null ? ByteArrayAndroidBitmap(largeIconBytes) : null,
      styleInformation: BigTextStyleInformation(message),
    );

    final iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      senderName,
      message,
      details,
      payload: 'chat:${senderName}', // Optional: You can encode chat info here
    );
  }

  void _handleNotificationTap(BuildContext context, String? payload) {
    if (payload != null && payload.startsWith('chat:')) {
      final senderName = payload.replaceFirst('chat:', '');
      // Navigate to chat or show profile (adjust route logic here)
      context.push('/chat/$senderName');
    }
  }

  void _navigateToChat(BuildContext context, String senderId) {
    // Navigate using sender ID
    context.push('/chat/$senderId');
  }
}
