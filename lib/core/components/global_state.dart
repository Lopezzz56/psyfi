import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GlobalState extends ChangeNotifier {
  final SupabaseClient supabase;
  String? userId;
  String? userRole;
  String? email;
  bool isInitialized = false;

  GlobalState({required this.supabase}) {
    _init();
  }

  Future<void> _init() async {
    if (kIsWeb) {
      final refreshToken = supabase.auth.currentSession?.refreshToken;
      if (refreshToken != null) {
        await supabase.auth.recoverSession(refreshToken);
      }
    }
    await restoreUser();
  }

Future<void> restoreUser() async {
  // If already initialized and userId is not null, skip reloading
  if (isInitialized && userId != null) {
    debugPrint('User already restored. Skipping...');
    return;
  }

  try {
    debugPrint('Restoring user...');

    final session = supabase.auth.currentSession;
    final user = session?.user;

    debugPrint('Session: $session');
    debugPrint('User from session: $user');

    if (user != null) {
      userId = user.id;

      final response = await supabase
          .from('users')
          .select('role')
          .eq('id', userId!)
          .maybeSingle();

      debugPrint('Role fetch response: $response');

      if (response != null && response['role'] != null) {
        userRole = response['role'];
      } else {
        userRole = 'user'; // Fallback
      }
    } else {
      debugPrint('No user session found');
      userId = null;
      userRole = null;
    }

    isInitialized = true;
    notifyListeners();
  } catch (e) {
    debugPrint('Error in restoreUser: $e');
    isInitialized = true;
    notifyListeners();
  }
}


  void setUserId(String id) {
    userId = id;
    notifyListeners();
  }

  void setUserRole(String role) {
    userRole = role;
    notifyListeners();
  }

  void setEmail(String e) {
    email = e;
    notifyListeners();
  }

  void setUser(String id, String role) {
    userId = id;
    userRole = role;
    notifyListeners();
  }

  void clearUser() {
    userId = null;
    userRole = null;
    notifyListeners();
  }
}
