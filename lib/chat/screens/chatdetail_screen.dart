import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:psy_fi/chat/controllers/chatdetail_controller.dart';
import 'package:psy_fi/chat/repos/chatdetail_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatDetailScreen extends StatefulWidget {
  final String currentUserId;
  final String peerId;
  final String peerName;
  final String peerImage;
  final SupabaseClient supabase;

  const ChatDetailScreen({
    Key? key,
    required this.currentUserId,
    required this.peerId,
    required this.peerName,
    required this.peerImage,
    required this.supabase,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late ChatDetailController _controller;
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final supabase = Supabase.instance.client;
    final repo = ChatDetailRepository(supabase);

    _controller = ChatDetailController(
      supabase: supabase,
      repo: repo,
      currentUserId: widget.currentUserId,
      peerId: widget.peerId,
    );

    _controller.listenToMessages();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.markSeen();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 70),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          CircleAvatar(
                            backgroundImage: NetworkImage(widget.peerImage),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            widget.peerName,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Error Banner
                    Consumer<ChatDetailController>(
                      builder: (context, controller, _) {
                        if (!controller.isConnected) {
                          return Container(
                            color: Colors.redAccent,
                            padding: const EdgeInsets.all(8),
                            child: const Text(
                              '⚠️ You are offline. Messages may not load.',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }
                        if (controller.error != null) {
                          return Container(
                            color: Colors.orangeAccent,
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              controller.error!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    const SizedBox(height: 8),

                    // Chat Area
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Consumer<ChatDetailController>(
                                builder: (context, controller, _) => ListView.builder(
                                  reverse: true,
                                  itemCount: controller.messages.length,
                                  itemBuilder: (_, index) {
                                    final msg = controller.messages[index];
                                    final isMe = msg['sender_id'] == widget.currentUserId;
                                    return Align(
                                      alignment: isMe
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 6),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isMe ? Colors.blue[200] : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          msg['message'],
                                          style: GoogleFonts.cormorantGaramond(fontSize: 16),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          // Input Field
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                            child: Consumer<ChatDetailController>(
                              builder: (context, controller, _) => Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _inputController,
                                      style: GoogleFonts.cormorantGaramond(fontSize: 18),
                                      decoration: InputDecoration(
                                        hintText: controller.sendDisabled
                                            ? 'Offline...'
                                            : 'Type a message...',
                                        fillColor: Colors.grey[100],
                                        filled: true,
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      enabled: !controller.sendDisabled,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.send),
                                    onPressed: controller.sendDisabled
                                        ? null
                                        : () {
                                            if (_inputController.text.trim().isNotEmpty) {
                                              controller.sendMessage(_inputController.text.trim());
                                              _inputController.clear();
                                            }
                                          },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
