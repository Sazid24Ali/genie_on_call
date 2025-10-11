import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:genie_on_call/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String? _selectedChatId;
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_selectedChatId != null && _messageController.text.isNotEmpty) {
      await _chatService.sendMessage(_selectedChatId!, _messageController.text);
      _messageController.clear();
    }
  }

  Future<void> _createGeneralChat() async {
    final chatId = await _chatService.createGeneralChat();
    if (chatId != null) {
      setState(() {
        _selectedChatId = chatId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createGeneralChat,
            tooltip: 'Start General Chat',
          ),
        ],
      ),
      body: Row(
        children: [
          // Chat list
          Expanded(
            flex: 1,
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getUserChats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final chats = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final data = chat.data() as Map<String, dynamic>;
                    final type = data['type'] ?? 'general';
                    final relatedBookingId = data['relatedBookingId'];
                    return ListTile(
                      title: Text(
                        type == 'general' ? 'General Chat' : 'Service Chat',
                      ),
                      subtitle: relatedBookingId != null
                          ? Text('Booking: $relatedBookingId')
                          : null,
                      selected: _selectedChatId == chat.id,
                      onTap: () {
                        setState(() {
                          _selectedChatId = chat.id;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          // Chat view
          if (_selectedChatId != null)
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _chatService.getMessages(_selectedChatId!),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final messages = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final data = message.data() as Map<String, dynamic>;
                            final isMe = data['senderId'] == _currentUser?.uid;
                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blue : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  data['message'] ?? '',
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type a message',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
