import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false; // To manage loading state for the button

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
          // Auto-retrieval or instant verification
          await _auth.signInWithCredential(credential);
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            // Optionally navigate to home if auto-verified
            // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
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
                builder: (context) => OTPScreen(verificationId: verificationId),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Login',
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        // Added SingleChildScrollView
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Stretch children horizontally
          children: [
            const SizedBox(height: 50), // Spacing from app bar
            const SizedBox(height: 40),
            const Text(
              "Enter your phone number to continue",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10, // Indian phone numbers are 10 digits
              decoration: InputDecoration(
                labelText: "Phone Number",
                hintText: "e.g., 9876543210",
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
                counterText: "", // Hide the default maxLength counter
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
                onPressed: _isLoading
                    ? null
                    : _sendOTP, // Disable button when loading
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
        ),
      ),
    );
  }
}
