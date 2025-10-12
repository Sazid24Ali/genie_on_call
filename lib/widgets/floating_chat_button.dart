import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/chat_screen.dart';

class FloatingChatButton extends StatelessWidget {
  const FloatingChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Navigate to chat screen with 'genie-support' room for executives
          // For agents, this can be used for executive communication; adjust room if needed
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatRoomId: 'genie-support',
                otherUserId: 'executive', // Fixed for genie/executive
              ),
            ),
          );
        }
      },
      backgroundColor: Colors.greenAccent.shade700,
      child: const Icon(
        Icons.chat_bubble_rounded,
        color: Colors.white,
        size: 28,
      ),
      tooltip: 'Chat with Genie/Executive',
    );
  }
}
