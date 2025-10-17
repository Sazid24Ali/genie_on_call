import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:genie_on_call/services/chat_service.dart';
import 'chat_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const int _recentBookingsPageSize = 5;
  bool _isCx = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserRole();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final user = _auth.currentUser;
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

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text('Not signed in')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Bookings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatsList(user.uid, isGeneral: true),
          _buildChatsList(user.uid, isGeneral: false),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _startNewChatFlow(context, user.uid),
      ),
    );
  }

  Widget _buildChatsList(String userId, {required bool isGeneral}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getUserChats(userId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data?.docs ?? [];
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final hasBookingId = data['bookingId'] != null;
          // print("The service name is ::: ${data['serviceName']}");
          return isGeneral ? !hasBookingId : hasBookingId;
        }).toList();
        if (filteredDocs.isEmpty)
          return const Center(child: Text('No chats yet.'));
        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final d = filteredDocs[index].data() as Map<String, dynamic>;
            final chatId = filteredDocs[index].id;
            final isClosed = d['status'] == 'closed';
            // print(d);
            final title =
                d['serviceName'] ??
                (d['bookingId'] != null
                    ? 'Bookings: ${d['bookingId']}'
                    : 'General Support');
            final subtitle = d['lastMessage'] ?? '';
            final createdAt = d['createdAt'] as Timestamp?;
            final dateString = createdAt != null
                ? DateFormat('MMM dd, yyyy').format(createdAt.toDate())
                : '';
            final hasUnread =
                (_isCx ? d['cxUnreadCount'] : d['userUnreadCount']) != null &&
                (_isCx ? d['cxUnreadCount'] : d['userUnreadCount']) > 0;
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(
                  title,
                  style: TextStyle(
                    color: isClosed ? Colors.grey : Colors.black,
                    fontWeight: isClosed ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isClosed ? Colors.grey.shade600 : Colors.black87,
                      ),
                    ),
                    Text(
                      dateString,
                      style: TextStyle(
                        fontSize: 12,
                        color: isClosed ? Colors.grey.shade500 : Colors.grey,
                      ),
                    ),
                  ],
                ),
                trailing: hasUnread
                    ? Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatRoomId: chatId,
                        otherUserId: d['cxId'] ?? 'support',
                      ),
                    ),
                  );
                },
                tileColor: isClosed ? Colors.grey.shade100 : null,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _startNewChatFlow(BuildContext context, String userId) async {
    // Ask whether booking or general
    final type = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Start a new chat'),
        content: const Text('Is this regarding a booking or general support?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, 'general'),
            child: const Text('General'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, 'booking'),
            child: const Text('Booking'),
          ),
        ],
      ),
    );

    if (type == null) return;

    if (type == 'general') {
      final chatId = await _chatService.getOrCreateGeneralChat(userId);
      // Create a chat request so CX can see and accept it
      await _chatService.createChatRequest(
        chatId: chatId,
        userId: userId,
        initialMessage: 'User initiated general support chat',
      );
      // Navigate to chat where user can type an initial message
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ChatScreen(chatRoomId: chatId, otherUserId: 'support'),
        ),
      );
      return;
    }

    // Booking path: fetch recent bookings and let user pick
    final bookingsSnap = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(_recentBookingsPageSize)
        .get();

    final bookings = bookingsSnap.docs;

    final selectedBookingId = await showDialog<String?>(
      context: context,
      builder: (c) => BookingPickerDialog(bookings: bookings),
    );

    if (selectedBookingId == null) return;

    final chatId = await _chatService.getOrCreateBookingChat(
      selectedBookingId,
      userId: userId,
    );

    // Create a chat request so CX can see and accept it
    await _chatService.createChatRequest(
      chatId: chatId,
      bookingId: selectedBookingId,
      userId: userId,
      initialMessage: 'User initiated chat regarding booking',
    );

    // Navigate user to the chat (messages will be visible to CX after acceptance)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(chatRoomId: chatId, otherUserId: 'support'),
      ),
    );
  }
}

class BookingPickerDialog extends StatefulWidget {
  final List<QueryDocumentSnapshot> bookings;
  const BookingPickerDialog({required this.bookings, super.key});

  @override
  State<BookingPickerDialog> createState() => _BookingPickerDialogState();
}

class _BookingPickerDialogState extends State<BookingPickerDialog> {
  String? _selected;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    // TODO: determine if there are more bookings to load; we can run a lightweight count or next page request.
    _hasMore =
        widget.bookings.length >= _ChatsListScreenState._recentBookingsPageSize;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select booking'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.bookings.isEmpty)
              const Text('No recent bookings found.'),
            if (widget.bookings.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.bookings.length,
                  itemBuilder: (context, index) {
                    final b =
                        widget.bookings[index].data() as Map<String, dynamic>;
                    final bid = widget.bookings[index].id;
                    return RadioListTile<String>(
                      title: Text('Booking: $bid'),
                      subtitle: Text(b['service'] ?? b['serviceName'] ?? ''),
                      value: bid,
                      groupValue: _selected,
                      onChanged: (v) => setState(() => _selected = v),
                    );
                  },
                ),
              ),
            if (_hasMore)
              TextButton(
                onPressed: () {
                  // Load more flow: close dialog and open a fuller booking selector screen
                  Navigator.pop(context, null);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FullBookingsScreen(),
                    ),
                  );
                },
                child: const Text('Load more bookings...'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Select'),
        ),
      ],
    );
  }
}

class FullBookingsScreen extends StatefulWidget {
  const FullBookingsScreen({super.key});

  @override
  State<FullBookingsScreen> createState() => _FullBookingsScreenState();
}

class _FullBookingsScreenState extends State<FullBookingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<QueryDocumentSnapshot> _bookings = [];
  bool _loading = false;
  DocumentSnapshot? _lastDoc;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading) return;
    setState(() => _loading = true);
    Query q = _firestore
        .collection('bookings')
        .where('userId', isEqualTo: _auth.currentUser!.uid)
        .orderBy('createdAt', descending: true)
        .limit(_pageSize);
    if (_lastDoc != null) q = q.startAfterDocument(_lastDoc!);
    final snap = await q.get();
    if (snap.docs.isNotEmpty) {
      _lastDoc = snap.docs.last;
      _bookings.addAll(snap.docs);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select booking')),
      body: ListView.builder(
        itemCount: _bookings.length + 1,
        itemBuilder: (context, index) {
          if (index == _bookings.length) {
            return _loading
                ? const Center(child: CircularProgressIndicator())
                : TextButton(
                    onPressed: _loadMore,
                    child: const Text('Load more'),
                  );
          }
          final b = _bookings[index].data() as Map<String, dynamic>;
          final id = _bookings[index].id;
          return ListTile(
            title: Text('Booking: $id'),
            subtitle: Text(b['service'] ?? b['serviceName'] ?? ''),
            onTap: () => Navigator.pop(context, id),
          );
        },
      ),
    );
  }
}
