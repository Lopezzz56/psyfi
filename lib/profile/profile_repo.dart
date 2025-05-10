import 'package:psy_fi/core/components/global_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepo {
  final supabase = Supabase.instance.client;

  /// Fetch user details (username, phone, email)
  Future<Map<String, String>?> getUserDetails(String userId, GlobalState global) async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle(); // safer

      if (response == null) return null;

      // Update global state
      global.setUserRole(response['role']);
      global.setUserId(response['id']);
      global.setEmail(response['email']);

      return {
        'username': response['username'],
        'email': response['email'],
        'phone': response['phone'],
      };
    } catch (e) {
      print("Error fetching user details: $e");
      return null;
    }
  }

  /// Sign Out
  Future<void> signOut(GlobalState global) async {
    try {
      await supabase.auth.signOut();
      global.clearUser(); // Clear the user data in global state
    } catch (e) {
      print("Error during sign-out: $e");
    }
  }
}
