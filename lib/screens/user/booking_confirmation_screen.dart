import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:genie_on_call/screens/booking_success_screen.dart';
import 'package:audioplayers/audioplayers.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final String serviceName;
  final double cost;
  final String description;
  final List<String> images;
  final String? recording;
  final String name;
  final String address;
  final String phoneNumber;
  final DateTime selectedDate;
  final String selectedTimeSlot;

  const BookingConfirmationScreen({
    super.key,
    required this.serviceName,
    required this.cost,
    required this.description,
    required this.images,
    this.recording,
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.selectedDate,
    required this.selectedTimeSlot,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isConfirming = false;
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playRecording() async {
    try {
      await _audioPlayer.play(DeviceFileSource(widget.recording!));
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error playing recording: $e')));
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> _confirmBooking() async {
    if (_currentUser == null) return;

    setState(() {
      _isConfirming = true;
    });

    try {
      // Upload images to Firebase Storage
      List<String> imageUrls = [];
      for (String path in widget.images) {
        String fileName = path.split('/').last;
        Reference ref = FirebaseStorage.instance.ref().child(
          'bookings/${_currentUser!.uid}/images/$fileName',
        );
        await ref.putFile(File(path));
        String url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      // Upload recording to Firebase Storage
      String? recordingUrl;
      if (widget.recording != null) {
        String fileName = widget.recording!.split('/').last;
        Reference ref = FirebaseStorage.instance.ref().child(
          'bookings/${_currentUser!.uid}/recordings/$fileName',
        );
        await ref.putFile(File(widget.recording!));
        recordingUrl = await ref.getDownloadURL();
      }

      // Create chat for the booking
      final chatRef = await _firestore.collection('chats').add({
        'participants': [
          _currentUser!.uid,
        ], // Initially only user, CX and agent will be added later
        'type': 'service-specific',
        'relatedBookingId': null, // Will set after booking creation
        'createdAt': FieldValue.serverTimestamp(),
      });

      final bookingRef = await _firestore.collection('bookings').add({
        'userId': _currentUser!.uid,
        'userName': widget.name,
        'userPhone': widget.phoneNumber,
        'userAddress': widget.address,
        'serviceName': widget.serviceName,
        'cost': widget.cost,
        'description': widget.description,
        'images': imageUrls,
        'recording': recordingUrl,
        'selectedDate': widget.selectedDate,
        'selectedTimeSlot': widget.selectedTimeSlot,
        'status': 'pending',
        'chatId': chatRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update chat with relatedBookingId
      await chatRef.update({'relatedBookingId': bookingRef.id});

      // Update user doc if needed
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'lastBookingId': bookingRef.id,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BookingSuccessScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error confirming booking: $e')));
      }
      setState(() {
        _isConfirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final formattedDate = dateFormat.format(widget.selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service: ${widget.serviceName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Cost: ₹${widget.cost.toStringAsFixed(0)}'),
                    const SizedBox(height: 8),
                    Text('Date: $formattedDate'),
                    Text('Time: ${widget.selectedTimeSlot}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Details:',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Name', widget.name),
                    _buildDetailRow('Phone', widget.phoneNumber),
                    _buildDetailRow('Address', widget.address),
                  ],
                ),
              ),
            ),
            if (widget.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Description:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(widget.description),
            ],
            if (widget.images.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Images:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Image.file(
                        File(widget.images[index]),
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ],
            if (widget.recording != null) ...[
              const SizedBox(height: 16),
              Text(
                'Recording:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                onPressed: _isPlaying ? _stopRecording : _playRecording,
                iconSize: 40,
                color: Colors.blueAccent,
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isConfirming ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isConfirming
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirm Booking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
