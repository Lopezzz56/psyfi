import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:psy_fi/core/components/global_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepo {
  final supabase = Supabase.instance.client;

  Future<String?> signUp({
    required String email,
    required String password,
    required String username,
    required String phone,
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'phone': phone},
      );

      if (response.user != null) {
        await supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'username': username,
          'phone': phone,
        });
        return null;
      }
      return "SignUp Failed";
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) return null;
      return "Invalid Credentials";
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> sendOtp({required String email}) async {
    try {
      await supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> saveUserData({
    required String id,
    required String email,
    required String username,
    required String phone,
    required DateTime createdAt,
  }) async {
    try {
      final response = await supabase
          .from('users')
          .insert({
            'id': id,
            'email': email,
            'username': username,
            'phone': phone,
            'created_at': createdAt.toIso8601String(),
            'role': 'user',
            'image_icon': null,
          })
          .select();

      if (response.isEmpty) {
        throw Exception("Insert blocked (RLS or DB error)");
      }
    } catch (e) {
      rethrow;
    }
  }
Future<String?> verifyOtp({
  required String email,
  required String otp,
  required String username,
  required String phone,
  required BuildContext context,
}) async {
  try {
    final response = await supabase.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.email,
    );

    final user = response.user;
    if (user != null) {
      // Insert user data if not already present
      final userCheck = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (userCheck == null) {
        await supabase.from('users').insert({
          'id': user.id,
          'email': email,
          'username': username,
          'phone': phone,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return null;
    } else {
      return "OTP verification failed.";
    }
  } catch (e) {
    return e.toString();
  }
}


  Future<String?> signOut(GlobalState global) async {
    try {
      await supabase.auth.signOut();
      global.clearUser();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
