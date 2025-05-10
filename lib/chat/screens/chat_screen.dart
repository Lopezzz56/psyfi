import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:psy_fi/chat/controllers/chat_controller.dart';
import 'package:psy_fi/chat/repos/chat_repo.dart';
import 'package:psy_fi/chat/screens/chatdetail_screen.dart';
import 'package:psy_fi/core/components/chat_tile.dart';
import 'package:psy_fi/core/components/encrypt.dart';
import 'package:psy_fi/core/components/loading_screen.dart';
import 'package:psy_fi/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';



class ChatScreen extends StatefulWidget {
  final String userId;
  final String role;

  const ChatScreen({Key? key, required this.userId, required this.role}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with RouteAware {
  late ChatScreenController controller;

@override
void initState() {
  super.initState();
  controller = Provider.of<ChatScreenController>(context, listen: false);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    controller.loadUsers(
      currentUserId: widget.userId,
      currentRole: widget.role,
    );
  });
}
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final route = ModalRoute.of(context);
  if (route != null) {
    print("✅ Subscribing to RouteObserver");
    routeObserver.subscribe(this, route);
  } else {
    print("❌ ModalRoute is null");
  }
}

@override
void dispose() {
  routeObserver.unsubscribe(this);
  // controller.dispose();
  super.dispose();
}


  @override
  void didPopNext() {
   print("Returned to ChatScreen");

    // Called when user returns to this screen (e.g. after popping ChatDetailScreen)
    controller.fetchChats(); // 🔁 Refresh unseen messages
  }



  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ChatScreenController>(context); // For rebuild
String decryptSafe(String? encrypted) {
  if (encrypted == null || encrypted.isEmpty) return '';
  try {
    return MessageCryptoHelper.decryptText(encrypted);
  } catch (_) {
    return '[Decryption Error]';
  }
}

    return Scaffold(
            backgroundColor: Colors.white,

body: SafeArea(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Custom Title
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Text(
          "💬 Chat",
          style: GoogleFonts.cormorantGaramond(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Filter Buttons
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FilterButton(
              text: 'Medical',
              selected: controller.currentFilter == UserFilter.medical,
              onTap: () => controller.applyFilter(UserFilter.medical),
            ),
            FilterButton(
              text: 'Normal Users',
              selected: controller.currentFilter == UserFilter.user,
              onTap: () => controller.applyFilter(UserFilter.user),
            ),
            FilterButton(
              text: 'All',
              selected: controller.currentFilter == UserFilter.all,
              onTap: () => controller.applyFilter(UserFilter.all),
            ),


          ],
        ),
      ),
      const SizedBox(height: 8),

      // Chat List
      Expanded(
        child: controller.isLoading
            ?  Center(child: const LoadingScreen(
        messages: [
          "We are here...",
          "Almost there...",
          "Hang tight...",
        ],
        progressColor: Colors.blue, // or your theme color
      ))
            : controller.filteredUsers.isEmpty
                ? const Center(child: Text('No users found'))
                : Padding(
padding: EdgeInsets.only(
  left: 8.0,
  right: 8.0,
  top: 8.0,
  bottom: 8.0 + MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight,
),
                    child: ListView.builder(
                      itemCount: controller.filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = controller.filteredUsers[index];
return ChatTile(
  name: user['user']['username'] ?? '',
  email: user['user']['email'] ?? '',
  imageUrl: user['user']['image_icon'],
  lastMessage: decryptSafe(user['lastMessage']),
  unseenCount: user['unseenCount'] ?? 0,
  onTap: () {
context.push('/chat-detail', extra: {
  'currentUserId': controller.currentUserId,
  'peerId': user['user']['id'],
  'peerName': user['user']['username'],
  'peerImage': user['user']['image_icon'] ?? '',
}).then((_) {
  // This block is executed when ChatDetailScreen is popped
  controller.fetchChats(); // Refresh chats
});

  },
);

                      },
                    ),
                  ),
      ),
    ],
  ),
),

    );
  }
}

class FilterButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const FilterButton({
    Key? key,
    required this.text,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? Colors.blueAccent : Colors.white,
        foregroundColor: selected ? Colors.white : Colors.black,
        side: const BorderSide(color: Colors.blueAccent),
      ),
      onPressed: onTap,
      child: Text(text,           
      style: GoogleFonts.cormorantGaramond(
            fontSize: 18,
            // fontWeight: FontWeight.bold,
          ),),
    );
  }
}
