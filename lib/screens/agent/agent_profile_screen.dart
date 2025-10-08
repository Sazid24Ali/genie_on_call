import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'agent_home_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/language_selector.dart';

class AgentProfileScreen extends StatefulWidget {
  const AgentProfileScreen({super.key});

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  List<String> selectedServices = [];
  Position? _currentPosition;
  bool _isLoading = false;
  bool _locationLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchExistingData();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _locationLoading = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          // Handle permission denied
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).locationPermissionContent,
                ),
              ),
            );
          }
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).errorGettingLocation(e.toString()),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _locationLoading = false;
      });
    }
  }

  Future<void> _fetchExistingData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final agentDoc = await _firestore
            .collection('agents')
            .doc(user.uid)
            .get();
        if (agentDoc.exists) {
          final data = agentDoc.data()!;
          nameController.text = data['name'] ?? '';
          experienceController.text = data['experience'] ?? '';
          selectedServices = List<String>.from(data['services'] ?? []);
          setState(() {});
        }
      } catch (e) {
        print("Error fetching existing data: $e");
      }
    }
  }

  Future<void> _saveProfile() async {
    if (nameController.text.trim().isEmpty ||
        selectedServices.isEmpty ||
        experienceController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(
            'Incomplete Profile',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Please fill all fields.',
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
      final user = _auth.currentUser;
      if (user != null) {
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        // Save to agents collection
        await _firestore.collection('agents').doc(user.uid).set({
          'userId': user.uid,
          'name': nameController.text.trim(),
          'phone': user.phoneNumber,
          'services': selectedServices,
          'experience': experienceController.text.trim(),
          'location': _currentPosition != null
              ? {
                  'lat': _currentPosition!.latitude,
                  'lng': _currentPosition!.longitude,
                }
              : null,
          'fcmToken': fcmToken,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update users doc with role
        await _firestore.collection('users').doc(user.uid).update({
          'role': 'agent',
        });

        if (mounted) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AgentHomeScreen()),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
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
              'Failed to save profile: $e',
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

  void _showServiceSelectionDialog() async {
    final servicesSnapshot = await _firestore.collection('services').get();
    final services = servicesSnapshot.docs
        .map((doc) => doc['name'] as String)
        .toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        List<String> tempSelected = List.from(selectedServices);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                AppLocalizations.of(context).selectServices,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: services.map((service) {
                    return CheckboxListTile(
                      title: Text(
                        service,
                        style: const TextStyle(fontFamily: 'Montserrat'),
                      ),
                      value: tempSelected.contains(service),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            tempSelected.add(service);
                          } else {
                            tempSelected.remove(service);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    AppLocalizations.of(context).cancel,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedServices = tempSelected;
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    AppLocalizations.of(context).done,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).agentProfile,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [LanguageSelector()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).manageProfileAndServices,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(fontFamily: 'Montserrat'),
              ),
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showServiceSelectionDialog,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).servicesOffered,
                  border: const OutlineInputBorder(),
                  labelStyle: const TextStyle(fontFamily: 'Montserrat'),
                ),
                child: Text(
                  selectedServices.isEmpty
                      ? 'Select services'
                      : selectedServices.join(', '),
                  style: const TextStyle(fontFamily: 'Montserrat'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: experienceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).yearsOfExperience,
                border: const OutlineInputBorder(),
                labelStyle: const TextStyle(fontFamily: 'Montserrat'),
              ),
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _locationLoading
                        ? AppLocalizations.of(context).detectingLocation
                        : _currentPosition != null
                        ? AppLocalizations.of(context).locationDisplay(
                            _currentPosition!.latitude.toStringAsFixed(4),
                            _currentPosition!.longitude.toStringAsFixed(4),
                          )
                        : AppLocalizations.of(context).locationNotDetected,
                    style: const TextStyle(fontFamily: 'Montserrat'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _getCurrentLocation,
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        AppLocalizations.of(context).saveProfile,
                        style: const TextStyle(
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
