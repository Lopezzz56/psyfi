import 'package:flutter/material.dart';
import 'package:psy_fi/chat/repos/chat_repo.dart';

enum UserFilter { all, medical, user }

class ChatScreenController extends ChangeNotifier {
  final ChatScreenRepository repository;

  ChatScreenController({required this.repository});

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];

  bool isLoading = false;
  String currentUserId = '';
  String currentRole = '';
  UserFilter currentFilter = UserFilter.all;

  void loadUsers({
    required String currentUserId,
    required String currentRole,
  }) async {
    this.currentUserId = currentUserId;
    this.currentRole = currentRole;

    isLoading = true;
    notifyListeners();

    try {
      _allUsers = await repository.fetchChatUsersWithMetadata(currentUserId);
      applyFilter(currentFilter); // Apply current filter after loading
            repository.subscribeToMessages(
        currentUserId: currentUserId,
        onNewMessage: fetchChats,
      );
    } catch (e) {
      print("Error loading users: $e");
    } finally {
      if (hasListeners) notifyListeners(); // ✅ Safe check

      isLoading = false;
    }
  }

  @override
  void dispose() {
    repository.unsubscribeFromMessages();
    super.dispose();
  }

  void applyFilter(UserFilter filter) {
    currentFilter = filter;

    switch (filter) {
      case UserFilter.medical:
        filteredUsers =
            _allUsers.where((user) => user['user']['role'] == 'medical').toList();
        break;
      case UserFilter.user:
        filteredUsers =
            _allUsers.where((user) => user['user']['role'] != 'medical').toList();
        break;
      case UserFilter.all:
        filteredUsers = _allUsers;
        break;
    }

    notifyListeners();
  }
  
Future<void> fetchChats() async {
  try {
    isLoading = true;
    if (hasListeners) notifyListeners();

    _allUsers = await repository.fetchChatUsersWithMetadata(currentUserId);
    applyFilter(currentFilter);
  } catch (e) {
    print("❌ Error refreshing chats: $e");
  } finally {
    isLoading = false;
    if (hasListeners) notifyListeners();
  }
}

  // void fetchChats() {
  //   // Refresh chat metadata (re-fetch unseen counts & last messages)
  //   loadUsers(currentUserId: currentUserId, currentRole: currentRole);
  // }
}
