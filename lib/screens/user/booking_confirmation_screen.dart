import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:genie_on_call/screens/booking_success_screen.dart';
import 'package:genie_on_call/services/chat_service.dart';
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
      // Require location permission and get current position before creating booking
      double? bookingLat;
      double? bookingLng;
      try {
        LocationPermission permission = await Geolocator.checkPermission();

        // Show rationale dialog if permission hasn't been granted
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (dctx) => AlertDialog(
              title: const Text('Why we need your location'),
              content: const Text(
                'We need your location to assign a nearby agent and verify the service address. The app will now request location permission.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dctx).pop(true),
                  child: const Text('Continue'),
                ),
              ],
            ),
          );
          if (proceed != true) {
            setState(() {
              _isConfirming = false;
            });
            return;
          }
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.deniedForever) {
          final openSettings = await showDialog<bool>(
            context: context,
            builder: (dctx) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                'Location permission is permanently denied. Please open app settings and grant location permission.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dctx).pop(true),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
          if (openSettings == true) await openAppSettings();
          setState(() {
            _isConfirming = false;
          });
          return;
        }

        if (permission != LocationPermission.always &&
            permission != LocationPermission.whileInUse) {
          if (mounted) {
            await showDialog<void>(
              context: context,
              builder: (dctx) => AlertDialog(
                title: const Text('Location Required'),
                content: const Text(
                  'Location permission is required to complete a booking. Please enable location permission and try again.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          setState(() {
            _isConfirming = false;
          });
          return;
        }

        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        bookingLat = pos.latitude;
        bookingLng = pos.longitude;

        // Save coordinates to user doc as well
        await _firestore.collection('users').doc(_currentUser.uid).set({
          'latitude': bookingLat,
          'longitude': bookingLng,
          // Keep legacy booking fields in user doc for compatibility
          'userLat': bookingLat,
          'userLng': bookingLng,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        print('Location permission/position error: $e');
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (dctx) => AlertDialog(
              title: const Text('Location Error'),
              content: const Text(
                'Unable to obtain your location. Please enable location services and try again.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        setState(() {
          _isConfirming = false;
        });
        return;
      }
      // Upload images to Firebase Storage
      List<String> imageUrls = [];
      for (String path in widget.images) {
        String fileName = path.split('/').last;
        Reference ref = FirebaseStorage.instance.ref().child(
          'bookings/${_currentUser.uid}/images/$fileName',
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
          'bookings/${_currentUser.uid}/recordings/$fileName',
        );
        await ref.putFile(File(widget.recording!));
        recordingUrl = await ref.getDownloadURL();
      }

      final bookingRef = await _firestore.collection('bookings').add({
        'userId': _currentUser.uid,
        'userName': widget.name,
        'userPhone': widget.phoneNumber,
        'userAddress': widget.address,
        'userLat': bookingLat,
        'userLng': bookingLng,
        // also set canonical fields for compatibility
        'latitude': bookingLat,
        'longitude': bookingLng,
        'serviceName': widget.serviceName,
        'cost': widget.cost,
        'description': widget.description,
        'images': imageUrls,
        'recording': recordingUrl,
        'selectedDate': widget.selectedDate,
        'selectedTimeSlot': widget.selectedTimeSlot,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update user doc if needed
      await _firestore.collection('users').doc(_currentUser.uid).update({
        'lastBookingId': bookingRef.id,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Ensure a chat document exists for this booking so CX/agents can chat.
      try {
        // Create ChatService instance and ensure chat exists for this booking
        final chatService = ChatService();
        final chatId = await chatService.getOrCreateChat(
          bookingId: bookingRef.id,
          userId: _currentUser.uid,
          cxId: null,
        );

        // Create/overwrite chat_requests/{chatId} so CX dashboard can pick it up
        await _firestore.collection('chat_requests').doc(chatId).set({
          'bookingId': bookingRef.id,
          'chatId': chatId,
          'userId': _currentUser.uid,
          'message': 'User initiated chat for booking',
          'status': 'new',
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        // Non-fatal: log and continue
        print('Failed to create chat for booking: $e');
      }

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
