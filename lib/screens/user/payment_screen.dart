import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  double? userLat;
  double? userLng;

  Future<bool> _ensureLocationAndSave() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

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
        if (proceed != true) return false;

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
        return false;
      }

      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
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
        return false;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      userLat = pos.latitude;
      userLng = pos.longitude;

      if (_currentUser != null) {
        await _firestore.collection('users').doc(_currentUser.uid).set({
          'latitude': userLat,
          'longitude': userLng,
          'userLat': userLat,
          'userLng': userLng,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return true;
    } catch (e) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (dctx) => AlertDialog(
            title: const Text('Location Error'),
            content: const Text(
              'Unable to obtain your current location. Please make sure location services are enabled and try again.',
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
      return false;
    }
  }

  Future<void> _finalizeBooking(String paymentMethod) async {
    try {
      // Ensure we have location and saved to user doc
      final ok = await _ensureLocationAndSave();
      if (!ok) return;

      if (_currentUser == null) return;

      // Update user profile with last minute changes
      await _firestore.collection('users').doc(_currentUser.uid).set({
        'name': widget.userName,
        'address': widget.userAddress,
        'phoneNumber': _currentUser.phoneNumber,
        'latitude': userLat,
        'longitude': userLng,
        'userLat': userLat,
        'userLng': userLng,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Create booking
      await _firestore.collection('bookings').add({
        'userId': _currentUser.uid,
        'userName': widget.userName,
        'userAddress': widget.userAddress,
        'userLat': userLat,
        'userLng': userLng,
        'latitude': userLat,
        'longitude': userLng,
        'userPhone': _currentUser.phoneNumber,
        'serviceName': widget.serviceName,
        'cost': widget.cost,
        'bookingDate': Timestamp.fromDate(widget.selectedDate),
        'bookingTime': widget.selectedTimeSlot,
        'paymentMethod': paymentMethod,
        'status': 'Pending',
        'agentId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to book service: $e')));
      }
      if (kDebugMode) print("Booking error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Select Payment Method',
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
        ),
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
