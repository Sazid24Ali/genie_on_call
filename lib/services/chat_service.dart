import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Send a message to a chat
  Future<void> sendMessage(String chatId, String message) async {
    if (_currentUser == null) return;

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': _currentUser!.uid,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  // Get messages for a chat
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Get all chats for the current user
  Stream<QuerySnapshot> getUserChats() {
    if (_currentUser == null) return const Stream.empty();

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: _currentUser!.uid)
        .snapshots();
  }

  // Create a general chat (if not exists)
  Future<String?> createGeneralChat() async {
    if (_currentUser == null) return null;

    // Check if general chat exists
    final query = await _firestore
        .collection('chats')
        .where('type', isEqualTo: 'general')
        .where('participants', arrayContains: _currentUser!.uid)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }

    // Create new general chat
    final chatRef = await _firestore.collection('chats').add({
      'participants': [_currentUser!.uid],
      'type': 'general',
      'relatedBookingId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return chatRef.id;
  }

  // Add participant to chat (e.g., when agent is assigned)
  Future<void> addParticipant(String chatId, String participantId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayUnion([participantId]),
    });
  }
}
