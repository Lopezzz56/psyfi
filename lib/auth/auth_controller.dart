import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:psy_fi/auth/auth_repo.dart';
import 'package:psy_fi/auth/screens/otp_screen.dart';
import 'package:psy_fi/core/components/global_state.dart';

class AuthController extends ChangeNotifier {
  final AuthRepo _authRepo = AuthRepo();
  bool isLoading = false;
  String errormessage = '';
  bool isOtpSent = false;

  String get errorMessageSafe => errormessage.isNotEmpty ? errormessage : '';

  Future<void> sendOtpForSignup({
    required String email,
    required String username,
    required String phone,
    required BuildContext context,
  }) async {
    isLoading = true;
    errormessage = '';
    notifyListeners();

    String? result = await _authRepo.sendOtp(email: email);

    if (result == null) {
      isOtpSent = true;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            email: email,
            username: username,
            phone: phone,
            isSignup: true,
          ),
        ),
      );
    } else {
      errormessage = result;
    }

    isLoading = false;
    notifyListeners();
  }
void setError(String message) {
  errormessage = message;
  notifyListeners();
}

  Future<void> sendOtp({required String email}) async {
    isLoading = true;
    errormessage = '';
    notifyListeners();

    String? result = await _authRepo.sendOtp(email: email);

    if (result == null) {
      isOtpSent = true;
    } else {
      errormessage = result;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> saveUserData({
    required String id,
    required String email,
    required String username,
    required String phone,
    required DateTime createdAt,
  }) async {
    try {
      isLoading = true;
      errormessage = '';
      notifyListeners();

      await _authRepo.saveUserData(
        id: id,
        email: email,
        username: username,
        phone: phone,
        createdAt: createdAt,
      );
    } catch (e) {
      errormessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


// In your AuthController:
Future<void> verifyOtpAndSaveUser({
  required String email,
  required String otp,
  required String username,
  required String phone,
  required BuildContext context,
}) async {
  isLoading = true;
  notifyListeners();

  // final authRepo = Provider.of<AuthRepo>(context, listen: false);
  final globalState = Provider.of<GlobalState>(context, listen: false);

  final error = await _authRepo.verifyOtp(
    email: email,
    otp: otp,
    username: username,
    phone: phone,
    context: context,
  );

  if (error == null) {
    debugPrint('OTP verification in AuthRepo successful.');
await globalState.restoreUser();
Navigator.pushReplacementNamed(context, '/home');
debugPrint('User ID in GlobalState after restoreUser: ${globalState.userId}');
debugPrint('User Role: ${globalState.userRole}');

  } else {
    errormessage = error;
    debugPrint('Error during OTP verification: $error');
  }

  isLoading = false;
  notifyListeners();
}

  Future<void> signIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    isLoading = true;
    errormessage = '';
    notifyListeners();

    String? result = await _authRepo.signIn(email: email, password: password);

    if (result == null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      errormessage = result;
    }

    isLoading = false;
    notifyListeners();
  }

  /// ✅ New method: SIGN OUT
  Future<void> signOut(BuildContext context) async {
    isLoading = true;
    errormessage = '';
    notifyListeners();

    final globalState = Provider.of<GlobalState>(context, listen: false);
    String? result = await _authRepo.signOut(globalState);

    if (result != null) {
      errormessage = result;
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }

    isLoading = false;
    notifyListeners();
  }
}
