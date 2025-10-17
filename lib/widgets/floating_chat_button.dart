import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/chats_list_screen.dart';
import '../services/chat_service.dart';

class FloatingChatButton extends StatefulWidget {
  final String? heroTag;

  const FloatingChatButton({super.key, this.heroTag});

  @override
  State<FloatingChatButton> createState() => _FloatingChatButtonState();
}

class _FloatingChatButtonState extends State<FloatingChatButton> {
  final ChatService _chatService = ChatService();
  bool _isCx = false;
  Offset _position = const Offset(0, 0);
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _isCx = userData['role'] == 'cx';
        });
      }
    }
  }

  void _updatePosition(Offset newPosition, Size screenSize) {
    setState(() {
      _position = Offset(
        newPosition.dx.clamp(0, screenSize.width - 56), // 56 is FAB size
        newPosition.dy.clamp(0, screenSize.height - 56),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenSize = MediaQuery.of(context).size;

    if (user == null) {
      return Positioned(
        right: 16 + _position.dx,
        bottom: 16 + _position.dy,
        child: GestureDetector(
          onPanStart: (_) => setState(() => _isDragging = true),
          onPanUpdate: (details) {
            _updatePosition(_position + details.delta, screenSize);
          },
          onPanEnd: (_) => setState(() => _isDragging = false),
          child: FloatingActionButton(
            heroTag: widget.heroTag ?? 'floating_chat_button',
            onPressed: null,
            backgroundColor: Colors.blueAccent.withOpacity(0.5),
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: Colors.white,
              size: 28,
            ),
            tooltip: 'Chat with Genie/Executive',
          ),
        ),
      );
    }

    return Positioned(
      right: 16 + _position.dx,
      bottom: 16 + _position.dy,
      child: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getUserChats(user.uid),
        builder: (context, snapshot) {
          int totalUnread = 0;
          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final unreadCount = _isCx
                  ? (data['cxUnreadCount'] ?? 0)
                  : (data['userUnreadCount'] ?? 0);
              totalUnread += unreadCount as int;
            }
          }

          return GestureDetector(
            onPanStart: (_) => setState(() => _isDragging = true),
            onPanUpdate: (details) {
              _updatePosition(_position - details.delta, screenSize);
            },
            onPanEnd: (_) => setState(() => _isDragging = false),
            child: Stack(
              children: [
                FloatingActionButton(
                  heroTag: widget.heroTag ?? 'floating_chat_button',
                  onPressed: _isDragging
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const ChatsListScreen(),
                            ),
                          );
                        },
                  backgroundColor: Colors.greenAccent.shade700,
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  tooltip: 'Chat with Genie/Executive',
                ),
                if (totalUnread > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        totalUnread > 99 ? '99+' : totalUnread.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
