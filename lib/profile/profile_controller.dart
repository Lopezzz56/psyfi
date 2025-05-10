import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:psy_fi/core/components/global_state.dart';
import 'profile_repo.dart';


class ProfileController with ChangeNotifier {
  final ProfileRepo _profileRepo = ProfileRepo();
  String errormessage = '';
  String username = "";
  String phone = "";
  String email = ""; // ✅ New field for email
  bool isLoading = false;

  /// Fetch user details & update state
Future<void> fetchUserDetails(GlobalState global) async {
  if (global.userId == null) return;

  isLoading = true;
  notifyListeners();

  final data = await _profileRepo.getUserDetails(global.userId!, global);
  if (data != null) {
    username = data['username'] ?? "";
    phone = data['phone'] ?? "";
    email = data['email'] ?? "";
  }

  isLoading = false;
  notifyListeners();
}


  /// Sign Out & navigate to login

  Future<void> signOut(BuildContext context) async {
    isLoading = true;
    errormessage = '';
    notifyListeners();

    final globalState = Provider.of<GlobalState>(context, listen: false); // Get GlobalState

    // Pass GlobalState to the signOut method
    await _profileRepo.signOut(globalState);

    Navigator.pushReplacementNamed(context, "/login");

    isLoading = false;
    notifyListeners();
  }
}
