import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'otp_screen.dart';
import 'user/home_screen.dart';
import 'agent/agent_profile_screen.dart';
import 'agent/agent_home_screen.dart';
import 'role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false; // To manage loading state for the button
  String? selectedRole;

  Future<void> _saveUserData(User user) async {
    try {
      final userDoc = await _firestore.collection("users").doc(user.uid).get();
      final bool isAgent = selectedRole == 'agent';

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
              "role": selectedRole,
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
          "role": selectedRole,
          "latitude": pos.latitude,
          "longitude": pos.longitude,
          "createdAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // For user, only ask location permission and save location if first time (no lat/lng saved)
        if (!userDoc.exists || userDoc.data()?['latitude'] == null || userDoc.data()?['longitude'] == null) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied ||
                permission == LocationPermission.deniedForever) {
              print("Location permissions are denied or denied forever.");
              await _firestore.collection("users").doc(user.uid).set({
                "phone": user.phoneNumber,
                "role": selectedRole,
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
            "role": selectedRole,
            "latitude": pos.latitude,
            "longitude": pos.longitude,
            "createdAt": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          // Location already saved, just update phone and role
          await _firestore.collection("users").doc(user.uid).set({
            "phone": user.phoneNumber,
            "role": selectedRole,
            "createdAt": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      print("Error saving user data or getting location: $e");
      // Even if location fails, try to save phone number and role
      await _firestore.collection("users").doc(user.uid).set({
        "phone": user.phoneNumber,
        "role": selectedRole,
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  void _sendOTP() async {
    if (phoneController.text.trim().isEmpty ||
        phoneController.text.trim().length != 10) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(
            'Invalid Phone Number',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Please enter a valid 10-digit phone number.',
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

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: "+91${phoneController.text.trim()}",
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval successful, sign in and save data
          try {
            UserCredential userCred = await _auth.signInWithCredential(
              credential,
            );
            if (userCred.user != null) {
              await _saveUserData(userCred.user!);
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                if (selectedRole == 'user') {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                } else if (selectedRole == 'agent') {
                  final agentDoc = await FirebaseFirestore.instance
                      .collection('agents')
                      .doc(userCred.user!.uid)
                      .get();
                  if (agentDoc.exists) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AgentHomeScreen(),
                      ),
                      (route) => false,
                    );
                  } else {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AgentProfileScreen(),
                      ),
                      (route) => false,
                    );
                  }
                } else {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RoleSelectionScreen(),
                    ),
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
                    'Auto-Verification Failed',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    'Auto-verification failed: ${e.toString()}. Please enter OTP manually.',
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
          }
        },
        verificationFailed: (FirebaseAuthException e) {
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
                  e.message ??
                      "An unknown error occurred during phone verification.",
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
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OTPScreen(
                  verificationId: verificationId,
                  selectedRole: selectedRole!,
                ),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            // This callback is fired when the SMS code auto-retrieval times out.
            // You might want to inform the user that they need to enter the OTP manually.
            // No specific UI action needed here as codeSent already navigated.
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text(
              'Error',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'An unexpected error occurred: ${e.toString()}',
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
    }
  }

  Widget _buildRoleSelection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 50),
        Text(
          "Choose how you want to use Genie On Call",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: () => setState(() => selectedRole = 'user'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
            ),
            child: const Text(
              "Login as User",
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: () => setState(() => selectedRole = 'agent'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
            ),
            child: const Text(
              "Login as Agent",
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
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 50),
        const SizedBox(height: 40),
        Text(
          "Enter your phone number to continue",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          decoration: InputDecoration(
            labelText: "Phone Number",
            hintText: "e.g., 9876543210",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '+91',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            labelStyle: const TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.grey,
            ),
            hintStyle: const TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.grey,
            ),
            counterText: "",
          ),
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOTP,
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
                    "Send OTP",
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            color: Color(0xDE000000),
            fontFamily: 'Montserrat',
          ),
          bodyMedium: TextStyle(
            color: Color(0x99000000),
            fontFamily: 'Montserrat',
          ),
        ),
        fontFamily: 'Montserrat',
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Login',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 1,
          leading: selectedRole != null
              ? IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  onPressed: () => setState(() => selectedRole = null),
                )
              : null,
        ),
        body: SingleChildScrollView(
          // Added SingleChildScrollView
          padding: const EdgeInsets.all(24),
          child: selectedRole == null
              ? _buildRoleSelection()
              : _buildPhoneInput(),
        ),
      ),
    );
  }
}
