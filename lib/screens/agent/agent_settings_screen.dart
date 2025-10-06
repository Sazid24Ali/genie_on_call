import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:genie_on_call/providers/theme_provider.dart';
import 'agent_home_screen.dart'; // Will create later

const MethodChannel _platform = MethodChannel(
  'com.example.genie_on_call/settings',
);

class AgentSettingsScreen extends StatefulWidget {
  const AgentSettingsScreen({super.key});

  @override
  State<AgentSettingsScreen> createState() => _AgentSettingsScreenState();
}

class _AgentSettingsScreenState extends State<AgentSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  List<String> selectedServices = [];
  Position? _currentPosition;
  bool _isLoading = false;
  bool _locationLoading = false;
  bool _notificationsEnabled = false;
  bool _isLoadingNotifications = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchExistingData();
    _checkNotificationPermission();
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
              const SnackBar(
                content: Text(
                  'Location permissions are required for agent profile.',
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
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
              title: const Text(
                'Select Services',
                style: TextStyle(
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
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
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
                  child: const Text(
                    'Done',
                    style: TextStyle(
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

  Future<void> _checkNotificationPermission() async {
    try {
      NotificationSettings settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      setState(() {
        _notificationsEnabled =
            settings.authorizationStatus == AuthorizationStatus.authorized;
        _isLoadingNotifications = false;
      });
    } catch (e) {
      print("Error checking notification permission: $e");
      setState(() {
        _isLoadingNotifications = false;
      });
    }
  }

  Future<void> openNotificationSettings() async {
    try {
      await _platform.invokeMethod('openNotificationSettings');
    } on PlatformException catch (e) {
      print("Failed to open notification settings: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Agent Settings',
          style: TextStyle(
            fontFamily: 'Montserrat',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complete your profile to start as an agent',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black54,
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
                decoration: const InputDecoration(
                  labelText: 'Services Offered',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(fontFamily: 'Montserrat'),
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
              decoration: const InputDecoration(
                labelText: 'Years of Experience',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(fontFamily: 'Montserrat'),
              ),
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _locationLoading
                        ? 'Detecting location...'
                        : _currentPosition != null
                        ? 'Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                        : 'Location not detected',
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

            // Notification Settings
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.notifications, color: Colors.green),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Push Notifications',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isLoadingNotifications
                                ? 'Checking status...'
                                : _notificationsEnabled
                                ? 'Notifications are enabled'
                                : 'Notifications are disabled. Tap to open settings.',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.blue),
                      onPressed: openNotificationSettings,
                      tooltip: 'Open Notification Settings',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Dark Mode Settings
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          themeProvider.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dark Mode',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                themeProvider.isDarkMode
                                    ? 'Dark theme is enabled'
                                    : 'Light theme is enabled',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (value) {
                            themeProvider.toggleTheme();
                          },
                          activeColor: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Location Services Info
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 16),
                        Text(
                          'Location Services',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Location permission is managed automatically. If denied, we use previously stored location details for better service matching.',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
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
                    : const Text(
                        'Save Profile',
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
