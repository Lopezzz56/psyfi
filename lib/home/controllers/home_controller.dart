import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreenController extends ChangeNotifier {
  final SupabaseClient supabase;

  HomeScreenController({required this.supabase});
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> saveFcmToken(String userId) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        final existing = await supabase
            .from('device_tokens')
            .select()
            .eq('user_id', userId)
            .eq('fcm_token', token)
            .maybeSingle();

        if (existing == null) {
          await supabase.from('device_tokens').insert({
            'user_id': userId,
            'fcm_token': token,
          });
        }
      }
    } catch (e) {
      print('FCM token save error: $e');
    }
  }
Future<List<String>> fetchBucketImages() async {
  final client = Supabase.instance.client;
  final bucketName = 'homecarousel';
  final folderPath = ''; // Files at the root

  List<String> urls = [];

  try {
    final files = await client.storage
        .from(bucketName)
        .list(path: folderPath, searchOptions: const SearchOptions());

    for (final file in files) {
      print('DEBUG file info: ${file.name}'); // Debugging file names
      final publicUrl = client.storage.from(bucketName).getPublicUrl(file.name);
      urls.add(publicUrl);
      print('✅ Found file: ${file.name} → $publicUrl');
    }

    if (urls.isEmpty) {
      print('⚠️ No files found in $bucketName.');
    }

    return urls;
  } catch (e, st) {
    print('❌ Error fetching images: $e\n$st');
    return [];
  }
}



   

}
