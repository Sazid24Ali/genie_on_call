import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

class PaymentScreen extends StatefulWidget {
  final String serviceName;
  final double cost;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final String userName;
  final String userAddress;

  const PaymentScreen({
    super.key,
    required this.serviceName,
    required this.cost,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.userName,
    required this.userAddress,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _finalizeBooking(String paymentMethod) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to book a service.'),
        ),
      );
      return;
    }

    try {
      // 1. Fetch user location
      final userDoc = await _firestore
          .collection('users')
          .doc(_currentUser.uid)
          .get();
      double? userLat;
      double? userLng;
      if (userDoc.exists) {
        final data = userDoc.data();
        userLat = data?['latitude'];
        userLng = data?['longitude'];
      }

      // 2. Update user profile (if any last-minute changes were made, though this is primarily done in BookingSlotScreen)
      await _firestore.collection('users').doc(_currentUser.uid).set({
        'name': widget.userName,
        'address': widget.userAddress,
        'phoneNumber': _currentUser.phoneNumber,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Create booking
      await _firestore.collection('bookings').add({
        'userId': _currentUser.uid,
        'userName': widget.userName,
        'userAddress': widget.userAddress,
        'userLat': userLat,
        'userLng': userLng,
        'userPhone': _currentUser.phoneNumber,
        'serviceName': widget.serviceName,
        'cost': widget.cost,
        'bookingDate': Timestamp.fromDate(widget.selectedDate),
        'bookingTime': widget.selectedTimeSlot,
        'paymentMethod': paymentMethod, // Store the chosen payment method
        'status': 'Pending', // Initial status
        'agentId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Show success message as a pop-up (AlertDialog)
      showDialog(
        context: context,
        barrierDismissible: false, // User must tap button to dismiss
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text(
              'Booking Confirmed!',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Service is booked, an executive will be assigned as soon as possible.',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.blueAccent,
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Dismiss the dialog
                  Navigator.popUntil(
                    context,
                    (route) => route.isFirst,
                  ); // Go back to the home screen
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to book service: $e')));
      print("Booking error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Select Payment Method',
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: Padding(
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
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cost: ₹${widget.cost.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Date: ${DateFormat('EEEE, MMM d, yyyy').format(widget.selectedDate)}',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Time: ${widget.selectedTimeSlot}',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Address: ${widget.userAddress}',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Choose Payment Option:',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Dummy UPI payment logic for now
                  _finalizeBooking('UPI');
                },
                icon: const Icon(Icons.payment_rounded, color: Colors.white),
                label: const Text(
                  'Payment via UPI (Dummy)',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  _finalizeBooking('Pay after service');
                },
                icon: const Icon(
                  Icons.wallet_rounded,
                  color: Colors.blueAccent,
                ),
                label: const Text(
                  'Pay after service',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
