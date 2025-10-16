import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> sendMessage(
    String chatRoomId,
    String text,
    String senderId,
  ) async {
    final chatRef = _firestore.collection('chats').doc(chatRoomId);

    // No need to fetch cxId here; server functions will manage unread counters.

    // Add the message
    await chatRef.collection('messages').add({
      'text': text,
      'senderId': senderId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update last-message fields on the chat doc for UI display (server function
    // will manage unread counters). This is best-effort and won't affect unread
    // accounting which is handled server-side to avoid double increments.
    try {
      await chatRef.set({
        'message': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // best effort only; ignore errors
    }
  }

  /// Find existing chat for [bookingId] or create a new chat document and return its id.
  /// If [bookingId] is null, creates a generic chat between the user and CX.
  Future<String> getOrCreateChat({
    String? bookingId,
    String? userId,
    String? cxId,
  }) async {
    // If bookingId provided, prefer a deterministic chat doc id to avoid
    // duplicate chat documents. Fall back to existing query behavior for
    // backwards compatibility if a deterministic doc is not present.
    if (bookingId != null && bookingId.isNotEmpty) {
      return await getOrCreateBookingChat(
        bookingId,
        userId: userId,
        cxId: cxId,
      );
    }

    // If no bookingId but userId provided, create or return a per-user general chat
    if (userId != null && userId.isNotEmpty) {
      return await getOrCreateGeneralChat(userId, cxId: cxId);
    }

    // Ultimate fallback: create a generic chat document (same as before)
    final ref = await _firestore.collection('chats').add({
      'userId': userId,
      'cxId': cxId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Returns the deterministic document id used for a booking chat.
  String _bookingDocId(String bookingId) => 'booking_$bookingId';

  /// (removed) _generalDocId was unused and removed to satisfy analyzer.

  /// Ensures a chat document exists for [bookingId] and returns its canonical id.
  /// Behavior:
  /// 1. If `chats/booking_{bookingId}` exists return it.
  /// 2. Else, search for any chat with field `bookingId == bookingId` (backcompat).
  /// 3. If found return that id.
  /// 4. Otherwise create `chats/booking_{bookingId}` deterministically and return id.
  Future<String> getOrCreateBookingChat(
    String bookingId, {
    String? userId,
    String? cxId,
  }) async {
    final docId = _bookingDocId(bookingId);
    final chatDocRef = _firestore.collection('chats').doc(docId);

    final snapshot = await chatDocRef.get();
    if (snapshot.exists) {
      final data = snapshot.data()!;
      if (data['serviceName'] == null) {
        // Fetch and update serviceName for existing chats
        String? serviceName;
        try {
          final bookingDoc = await _firestore
              .collection('bookings')
              .doc(bookingId)
              .get();
          if (bookingDoc.exists) {
            serviceName =
                bookingDoc.data()?['service'] ??
                bookingDoc.data()?['serviceName'];
          }
        } catch (e) {
          // Ignore errors
        }
        if (serviceName != null) {
          await chatDocRef.update({'serviceName': serviceName});
        }
      }
      return chatDocRef.id;
    }

    // Backwards compatibility: maybe an existing chat was created with a random id
    final q = await _firestore
        .collection('chats')
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) {
      final existingChatId = q.docs.first.id;
      final existingData = q.docs.first.data();
      if (existingData['serviceName'] == null) {
        // Fetch and update serviceName for existing chats
        String? serviceName;
        try {
          final bookingDoc = await _firestore
              .collection('bookings')
              .doc(bookingId)
              .get();
          if (bookingDoc.exists) {
            serviceName =
                bookingDoc.data()?['service'] ??
                bookingDoc.data()?['serviceName'];
          }
        } catch (e) {
          // Ignore errors
        }
        if (serviceName != null) {
          await _firestore.collection('chats').doc(existingChatId).update({
            'serviceName': serviceName,
          });
        }
      }
      return existingChatId;
    }

    // Fetch booking to get service name
    String? serviceName;
    try {
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();
      if (bookingDoc.exists) {
        serviceName =
            bookingDoc.data()?['service'] ?? bookingDoc.data()?['serviceName'];
      }
    } catch (e) {
      // Ignore errors, serviceName remains null
    }

    // Create deterministic document id to avoid duplicates from concurrent clients
    await chatDocRef.set({
      'bookingId': bookingId,
      'serviceName': serviceName,
      'userId': userId,
      'cxId': cxId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return chatDocRef.id;
  }

  /// Creates a new general chat document for each support request and returns its id.
  /// This ensures each general support chat is separate, not reusing the same conversation.
  Future<String> getOrCreateGeneralChat(String userId, {String? cxId}) async {
    final ref = await _firestore.collection('chats').add({
      'userId': userId,
      'cxId': cxId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Stream chats where the user is a participant (userId matches).
  Stream<QuerySnapshot> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream chats where the user is a participant (userId matches) filtered by status.
  Stream<QuerySnapshot> getUserChatsByStatus(String userId, String status) {
    return _firestore
        .collection('chats')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Create a chat request by setting the chat document status to 'requested'
  /// and adding the initial message to the messages subcollection.
  Future<void> createChatRequest({
    required String chatId,
    String? bookingId,
    required String userId,
    required String initialMessage,
    String? serviceName,
  }) async {
    final chatRef = _firestore.collection('chats').doc(chatId);
    final chatSnap = await chatRef.get();
    if (!chatSnap.exists) {
      // Create a minimal chat doc if it doesn't exist. BookingId may be null.
      await chatRef.set({
        'bookingId': bookingId,
        'userId': userId,
        'cxId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'requested',
        'serviceName': serviceName,
      });
    } else {
      // Mark status requested if present
      await chatRef.set({'status': 'requested'}, SetOptions(merge: true));
    }

    // Add the initial message to the messages subcollection
    await chatRef.collection('messages').add({
      'text': initialMessage,
      'senderId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Set last message and timestamp; do NOT touch unread counters here because
    // the server-side function updates unread counts atomically.
    try {
      await chatRef.set({
        'message': initialMessage,
        'lastMessageAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore
    }
  }
}
