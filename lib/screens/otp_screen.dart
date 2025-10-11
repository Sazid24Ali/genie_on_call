import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'role_selection_screen.dart';
import 'user/home_screen.dart';
import 'agent/agent_profile_screen.dart';
import 'agent/agent_home_screen.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String selectedRole;
  const OTPScreen({
    super.key,
    required this.verificationId,
    required this.selectedRole,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false; // To manage loading state for the button

  Future<void> _saveUserData(User user) async {
    try {
      final userDoc = await _firestore.collection("users").doc(user.uid).get();
      final bool isAgent = widget.selectedRole == 'agent';

      // For agent, always require location permission and update location
      if (isAgent) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) {
            // Handle cases where permission is denied
            print("Location permissions are denied or denied forever.");
            // You might want to show an alert here as well
            // For now, proceed without location if permission is denied
            await _firestore.collection("users").doc(user.uid).set({
              "phone": user.phoneNumber,
              "role": widget.selectedRole,
              "createdAt": FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            return;
          }
        }

        Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        await _firestore.collection("users").doc(user.uid).set({
          "phone": user.phoneNumber,
          "role": widget.selectedRole,
          "latitude": pos.latitude,
          "longitude": pos.longitude,
          "createdAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // For user, only ask location permission and save location if first time (no homeAddress saved)
        if (!userDoc.exists ||
            userDoc.data()?['homeAddress'] == null ||
            userDoc.data()?['homeAddress'].isEmpty) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied ||
                permission == LocationPermission.deniedForever) {
              print("Location permissions are denied or denied forever.");
              await _firestore.collection("users").doc(user.uid).set({
                "phone": user.phoneNumber,
                "role": widget.selectedRole,
                "createdAt": FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              return;
            }
          }

          Position pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          // Reverse geocode to get address
          String homeAddress = "Unknown Address";
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              pos.latitude,
              pos.longitude,
            );
            if (placemarks.isNotEmpty) {
              final Placemark place = placemarks.first;
              homeAddress = [
                place.street,
                place.subLocality,
                place.locality,
                place.administrativeArea,
                place.postalCode,
                place.country,
              ].where((element) => element != null && element.isNotEmpty).join(', ');
            }
          } catch (e) {
            print("Error reverse geocoding: $e");
          }

          await _firestore.collection("users").doc(user.uid).set({
            "phone": user.phoneNumber,
            "role": widget.selectedRole,
            "homeLat": pos.latitude,
            "homeLng": pos.longitude,
            "homeAddress": homeAddress,
            "createdAt": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          // Address already saved, just update phone and role
          await _firestore.collection("users").doc(user.uid).set({
            "phone": user.phoneNumber,
            "role": widget.selectedRole,
            "createdAt": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      print("Error saving user data or getting location: $e");
      // Even if location fails, try to save phone number and role
      await _firestore.collection("users").doc(user.uid).set({
        "phone": user.phoneNumber,
        "role": widget.selectedRole,
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  void _verifyOTP() async {
    if (otpController.text.trim().isEmpty ||
        otpController.text.trim().length != 6) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(
            'Invalid OTP',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Please enter the 6-digit OTP.',
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: widget.verificationId,
      smsCode: otpController.text.trim(),
    );

    try {
      UserCredential userCred = await _auth.signInWithCredential(credential);
      if (userCred.user != null) {
        await _saveUserData(userCred.user!);

        if (mounted) {
          if (widget.selectedRole == 'user') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          } else if (widget.selectedRole == 'agent') {
            // Check if agent profile exists
            final agentDoc = await _firestore
                .collection('agents')
                .doc(userCred.user!.uid)
                .get();
            if (agentDoc.exists) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AgentHomeScreen()),
                (route) => false,
              );
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AgentProfileScreen()),
                (route) => false,
              );
            }
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text(
              'Verification Failed',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Invalid OTP or an error occurred: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Verify OTP',
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 50),
            const SizedBox(height: 40),
            Text(
              "Enter the 6-digit code sent to your phone number",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: "OTP",
                hintText: "------",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.blueAccent.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.blueAccent,
                    width: 2,
                  ),
                ),
                labelStyle: const TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.grey,
                ),
                hintStyle: const TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.grey,
                ),
                counterText: "", // Hide the default maxLength counter
              ),
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                letterSpacing: 10,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Verify OTP",
                        style: TextStyle(
                          fontFamily: 'Montserrat',
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
}
