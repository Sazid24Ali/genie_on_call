import 'package:flutter/material.dart';
import '../screens/chat_screen.dart';

class FloatingChatButton extends StatelessWidget {
  const FloatingChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        );
      },
      backgroundColor: Colors.blueAccent,
      child: const Icon(Icons.chat, color: Colors.white),
    );
  }
}
