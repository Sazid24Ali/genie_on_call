import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/chat_service.dart';

class _VideoPlayerWidget extends StatefulWidget {
  final String url;

  const _VideoPlayerWidget({required this.url});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load video: $error';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _openInWebView() {
    print('Debug: Opening video in webview, URL: ${widget.url}');
    final webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { margin: 0; padding: 0; background: black; display: flex; justify-content: center; align-items: center; height: 100vh; }
                video { max-width: 100%; max-height: 100%; }
            </style>
        </head>
        <body>
            <video controls autoplay muted>
                <source src="${widget.url}">
                Your browser does not support the video tag.
            </video>
        </body>
        </html>
      ''');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(child: WebViewWidget(controller: webViewController)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 250, maxHeight: 250),
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              const Text(
                'Video failed to load',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _openInWebView,
                child: const Text('Open in Browser'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 250, maxHeight: 250),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 250, maxHeight: 250),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          if (!_controller.value.isPlaying)
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.white, size: 50),
              onPressed: _togglePlayPause,
            ),
          if (_controller.value.isPlaying)
            IconButton(
              icon: const Icon(Icons.pause, color: Colors.white, size: 50),
              onPressed: _togglePlayPause,
            ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  String _title = 'Chat';
  Map<String, dynamic>? _bookingData;
  bool _isClosed = false;
  bool _isCx = false;
  String? _chatCxId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await showDialog<XFile?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Media'),
        content: const Text('Choose an image or video to attach.'),
        actions: [
          TextButton(
            onPressed: () async {
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
              );
              Navigator.of(context).pop(image);
            },
            child: const Text('Image'),
          ),
          TextButton(
            onPressed: () async {
              final XFile? video = await picker.pickVideo(
                source: ImageSource.gallery,
              );
              Navigator.of(context).pop(video);
            },
            child: const Text('Video'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (pickedFile != null) {
      await _uploadMedia(pickedFile);
    }
  }

  Future<void> _uploadMedia(XFile file) async {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final Reference storageRef = FirebaseStorage.instance.ref().child(
        'chat_media/$fileName',
      );
      final UploadTask uploadTask = storageRef.putFile(File(file.path));
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Send message with media URL
      await _chatService.sendMessage(
        widget.chatRoomId,
        'Media: $downloadUrl',
        FirebaseAuth.instance.currentUser!.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Media uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading media: $e')));
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          _isCx = userData['role'] == 'cx';
        }
      }

      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .get();
      if (chatDoc.exists) {
        final data = chatDoc.data()!;
        _isClosed = data['status'] == 'closed';
        _chatCxId = data['cxId'] as String?;
        if (data['bookingId'] != null) {
          final bookingDoc = await FirebaseFirestore.instance
              .collection('bookings')
              .doc(data['bookingId'])
              .get();
          if (bookingDoc.exists) {
            final bookingData = bookingDoc.data()!;
            final serviceName =
                bookingData['service'] ??
                bookingData['serviceName'] ??
                'Booking';
            setState(() {
              _title = 'Chat: $serviceName';
              _bookingData = bookingData;
            });
          }
        } else {
          setState(() => _title = 'General Support');
        }
      }

      // Reset unread count when opening the chat based on user role
      final updateData = _isCx ? {'cxUnreadCount': 0} : {'userUnreadCount': 0};
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .update(updateData);
    } catch (e) {
      setState(() => _title = 'Chat');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          if (!_isClosed &&
              _isCx) // Only show close button if not closed and user is CX
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Close Chat'),
                    content: const Text(
                      'Are you sure you want to close this chat?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('chats')
                        .doc(widget.chatRoomId)
                        .update({
                          'status': 'closed',
                          'closedAt': Timestamp.now(),
                          'closedBy': FirebaseAuth.instance.currentUser!.uid,
                        });
                    if (mounted) {
                      setState(() => _isClosed = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chat closed successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error closing chat: $e')),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_bookingData != null) ...[
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Booking Details'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service: ${_bookingData!['service'] ?? _bookingData!['serviceName'] ?? 'N/A'}',
                          ),
                          Text('Status: ${_bookingData!['status'] ?? 'N/A'}'),
                          Text(
                            'User: ${_bookingData!['userName'] ?? _bookingData!['userId'] ?? 'N/A'}',
                          ),
                          Text('Phone: ${_bookingData!['userPhone'] ?? 'N/A'}'),
                          Text(
                            'Address: ${_bookingData!['userAddress'] ?? 'N/A'}',
                          ),
                          Text(
                            'Date/Time: ${_bookingData!['bookingDate'] != null ? (_bookingData!['bookingDate'] as Timestamp).toDate().toLocal().toString().split(' ')[0] : 'N/A'} at ${_bookingData!['bookingTime'] ?? 'N/A'}',
                          ),
                          Text('Cost: ₹${_bookingData!['cost'] ?? 'N/A'}'),
                          Text(
                            'Description: ${_bookingData!['description'] ?? 'N/A'}',
                          ),
                          if (_bookingData!['images'] != null &&
                              (_bookingData!['images'] as List).isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Images: ${(_bookingData!['images'] as List).length} available',
                            ),
                          ],
                          if (_bookingData!['recording'] != null) ...[
                            const SizedBox(height: 4),
                            Text('Recording: Available'),
                          ],
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                final messages = snapshot.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Scroll to the bottom after the frame is built
                  if (mounted) {
                    // Assuming the ListView has a ScrollController, but since it's not, we can use a GlobalKey or adjust
                    // For simplicity, since ListView.builder doesn't have a controller, we can reverse the list and scroll to top
                  }
                });
                return ListView.builder(
                  reverse: true, // Reverse the list to show latest at bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[messages.length - 1 - index].data()
                            as Map<String, dynamic>; // Adjust index for reverse
                    final isMe =
                        message['senderId'] ==
                        FirebaseAuth.instance.currentUser!.uid;
                    final isFromCx =
                        _chatCxId != null && message['senderId'] == _chatCxId;

                    // Show blue only when the CX sent the message and the current
                    // user is not the sender. Otherwise keep user's own messages
                    // a different color (green) and other messages grey.
                    Color bubbleColor;
                    if (isFromCx && !isMe) {
                      bubbleColor = Colors.blue;
                    } else if (isMe) {
                      bubbleColor = Colors.green;
                    } else {
                      bubbleColor = Colors.grey;
                    }

                    Widget messageWidget;
                    final text = message['text'] as String;
                    if (text.startsWith('Media: ')) {
                      final url = text.substring(7);
                      final isImage =
                          url.contains('.jpg') ||
                          url.contains('.jpeg') ||
                          url.contains('.png') ||
                          url.contains('.gif') ||
                          url.contains('.webp');
                      if (isImage) {
                        messageWidget = Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: GestureDetector(
                            onTap: () async {
                              try {
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Unable to open media URL',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error opening media: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Image.network(
                              url,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 200,
                                  height: 200,
                                  color: Colors.grey,
                                  child: const Center(
                                    child: Text(
                                      'Failed to load image',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      } else {
                        // For videos or other media, show inline player or link
                        final isVideo =
                            url.contains('.mp4') ||
                            url.contains('.mov') ||
                            url.contains('.avi') ||
                            url.contains('.mkv');
                        if (isVideo) {
                          messageWidget = Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _VideoPlayerWidget(url: url),
                          );
                        } else {
                          // For other media, show attachment link
                          messageWidget = Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Attachment',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    try {
                                      final uri = Uri.parse(url);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      } else {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Unable to open media URL',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error opening media: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'View Media',
                                      style: TextStyle(
                                        color: Colors.white,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    } else {
                      messageWidget = Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          text,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return ListTile(
                      title: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: messageWidget,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isClosed) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red[100],
              child: const Text(
                'This chat is closed. You can view messages but cannot send new ones.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _isClosed ? null : _pickMedia,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                    enabled: !_isClosed,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isClosed
                      ? null
                      : () {
                          if (_messageController.text.isNotEmpty) {
                            _chatService.sendMessage(
                              widget.chatRoomId,
                              _messageController.text,
                              FirebaseAuth.instance.currentUser!.uid,
                            );
                            _messageController.clear();
                          }
                        },
                ),
                if (_isCx) // Only show close button in input row if user is CX
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.red,
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Close Chat'),
                          content: const Text(
                            'Are you sure you want to close this chat?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        try {
                          await FirebaseFirestore.instance
                              .collection('chats')
                              .doc(widget.chatRoomId)
                              .update({
                                'status': 'closed',
                                'closedAt': Timestamp.now(),
                                'closedBy':
                                    FirebaseAuth.instance.currentUser!.uid,
                              });
                          if (mounted) {
                            setState(() => _isClosed = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Chat closed successfully'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error closing chat: $e')),
                            );
                          }
                        }
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
