import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:genie_on_call/utils/coords.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'agent_bookings_screen.dart';
import 'agent_earnings_screen.dart';
import 'agent_profile_screen.dart';
import 'agent_settings_screen.dart';
import '../chats_list_screen.dart';
import '../login_screen.dart';
import 'package:genie_on_call/widgets/app_language_action.dart';
import 'package:genie_on_call/widgets/floating_chat_button.dart';

// Helper function to map icon strings from Firestore to IconData
IconData getIconData(String iconName) {
  switch (iconName) {
    case 'ac_unit_rounded':
      return Icons.ac_unit_rounded;
    case 'cleaning_services_rounded':
      return Icons.cleaning_services_rounded;
    case 'bolt_rounded':
      return Icons.bolt_rounded;
    case 'handyman_rounded':
      return Icons.handyman_rounded;
    case 'plumbing_rounded':
      return Icons.plumbing_rounded;
    case 'flash_on_rounded':
      return Icons.flash_on_rounded;
    case 'format_paint_rounded':
      return Icons.format_paint_rounded;
    case 'chair_alt_rounded':
      return Icons.chair_alt_rounded;
    case 'door_front_rounded':
      return Icons.door_front_door_rounded;
    case 'build_rounded':
      return Icons.build_rounded;
    case 'water_drop_rounded':
      return Icons.water_drop_rounded;
    case 'electrical_services_rounded':
      return Icons.electrical_services_rounded;
    case 'power_rounded':
      return Icons.power_rounded;
    case 'add_circle_rounded':
      return Icons.add_circle_rounded;
    case 'format_color_fill_rounded':
      return Icons.format_color_fill_rounded;
    case 'brush_rounded':
      return Icons.brush_rounded;
    case 'local_gas_station_rounded':
      return Icons.local_gas_station_rounded;
    default:
      return Icons.miscellaneous_services_rounded;
  }
}

class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key});

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _agentName;
  String? _agentPhoneNumber;
  List<String> _agentServices = [];
  int _acceptedJobs = 0;
  double _earnings = 0.0;

  List<int> ranges = [5, 10, 15, 20, 25];
  int _selectedRange = 10;
  Position? _agentPosition;

  bool _isInitialDataFetched = false;

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialDataFetched) {
      _fetchAgentData();
      _fetchStats();
      _getAgentLocation();
      _isInitialDataFetched = true;
    }
  }

  Future<void> _fetchAgentData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final agentDoc = await _firestore
            .collection('agents')
            .doc(user.uid)
            .get();
        if (agentDoc.exists) {
          if (mounted) {
            setState(() {
              _agentName = agentDoc['name'];
              _agentPhoneNumber = user.phoneNumber;
              _agentServices = List<String>.from(agentDoc['services'] ?? []);
            });
          }
        }
      } catch (e) {
        print("Error fetching agent name: $e");
      }
    }
  }

  Future<void> _fetchStats() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Pending jobs assigned to this agent
        final pendingQuery = await _firestore
            .collection('bookings')
            .where('agentId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'Accepted')
            .get();
        setState(() {
          _acceptedJobs = pendingQuery.docs.length;
        });

        // Finished jobs for earnings
        final finishedQuery = await _firestore
            .collection('bookings')
            .where('agentId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'Finished')
            .get();
        double totalEarnings = 0.0;
        for (var doc in finishedQuery.docs) {
          totalEarnings += (doc['cost'] as num?)?.toDouble() ?? 0.0;
        }
        setState(() {
          _earnings = totalEarnings;
        });

        // Pending bookings without agentId (for potential jobs)
        setState(() {});
      } catch (e) {
        print("Error fetching stats: $e");
      }
    }
  }

  Future<void> _getAgentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permissions are required to filter jobs by distance.',
              ),
            ),
          );
          return;
        }
      }
      _agentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {});
    } catch (e) {
      print("Error getting location: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    }
  }

  Future<void> _acceptBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'agentId': _auth.currentUser!.uid,
        'status': 'Accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Booking accepted!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error accepting booking: $e')));
      }
    }
  }

  Future<void> _finishBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'Finished',
        'finishedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking marked as finished!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error finishing booking: $e')));
      }
    }
  }

  // --- FCM Methods Start ---
  Future<void> _setupFCM() async {
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

    print('User granted permission: ${settings.authorizationStatus}');

    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $token");

    if (token != null && _auth.currentUser != null) {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("FCM Token saved to Firestore for user: ${_auth.currentUser!.uid}");
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print(
          'Message also contained a notification: ${message.notification!.title} - ${message.notification!.body}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.notification!.title ?? 'New Notification',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.greenAccent.shade700,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to bookings
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AgentBookingsScreen(),
                  ),
                );
              },
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      print('Message data: ${message.data}');
    });

    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      print(
        'App opened from terminated state by notification: ${initialMessage.data}',
      );
    }
  }
  // --- FCM Methods End ---

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Logout',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Montserrat', color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _auth.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text(
              'Logout',
              style: TextStyle(fontFamily: 'Montserrat', color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: const FloatingChatButton(),
      appBar: AppBar(
        title: Text(
          'Genie On Call - Agent',
          style: TextStyle(
            fontFamily: 'Montserrat',
            color:
                Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
        ),
        elevation: 1,
        actions: const [AppLanguageAction()],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Earnings Card Only
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AgentEarningsScreen(),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        color: Colors.green,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${_earnings.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Total Earnings',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color ??
                                    Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // My Services Expandable Section
            ExpansionTile(
              title: Text(
                'My Services',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.black87,
                ),
              ),
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('services').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("No services available."),
                      );
                    }

                    final services = snapshot.data!.docs;
                    final filteredServices = services.where((doc) {
                      final serviceName = doc['name'] ?? '';
                      return _agentServices.contains(serviceName);
                    }).toList();

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredServices.length + 1,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 18,
                            crossAxisSpacing: 18,
                            childAspectRatio: 0.9,
                          ),
                      itemBuilder: (context, index) {
                        if (index == filteredServices.length) {
                          // Add service tile
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 4,
                            shadowColor: Colors.greenAccent.withOpacity(0.1),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AgentProfileScreen(),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.grey.withOpacity(
                                        0.1,
                                      ),
                                      radius: 28,
                                      child: const Icon(
                                        Icons.add,
                                        size: 32,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Add Service',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        } else {
                          final service =
                              filteredServices[index].data()
                                  as Map<String, dynamic>;
                          final serviceName =
                              service['name'] ?? 'Unknown Service';
                          final serviceIconName = service['icon'] ?? '';

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 4,
                            shadowColor: Colors.greenAccent.withOpacity(0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.greenAccent
                                        .withOpacity(0.08),
                                    radius: 28,
                                    child: Icon(
                                      getIconData(serviceIconName),
                                      size: 32,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    serviceName,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color ??
                                          Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Scheduled Jobs',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('bookings')
                  .where('agentId', isEqualTo: _auth.currentUser!.uid)
                  .where('status', isEqualTo: 'Accepted')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No scheduled jobs.",
                      style: TextStyle(
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.black87,
                      ),
                    ),
                  );
                }

                final bookings = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking =
                        bookings[index].data() as Map<String, dynamic>;
                    final bookingId = bookings[index].id;
                    final service = booking['serviceName'] ?? 'Unknown Service';
                    final location =
                        booking['userAddress'] ?? 'Location not available';
                    final cost = booking['cost'] ?? 0.0;
                    // final bookingDate = booking['selectedDate'];
                    // final String formattedDate;
                    // if (bookingDate is Timestamp) {
                    //   final DateTime bookingDateTime = bookingDate.toDate();
                    //   formattedDate = DateFormat(
                    //     'MMM d, yyyy',
                    //   ).format(bookingDateTime);
                    // } else {
                    //   formattedDate = 'Date not available';
                    // }
                    final Timestamp bookingTimestamp =
                        booking['selectedDate'] as Timestamp;
                    final DateTime bookingDateTime = bookingTimestamp.toDate();
                    final String formattedDate = DateFormat(
                      'MMM d, yyyy',
                    ).format(bookingDateTime);

                    final String bookingTime =
                        booking['selectedTimeSlot'] ?? 'Time not specified';
                    final String userName = booking['userName'] ?? 'Customer';
                    final String userPhone =
                        booking['userPhone'] ?? 'Not provided';
                    final String description =
                        'Date: $formattedDate\nTime: $bookingTime';

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AgentBookingsScreen(),
                          ),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    getIconData(booking['icon'] ?? ''),
                                    color: Colors.green,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      service,
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color ??
                                            Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₹${cost.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                description,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 14,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color ??
                                      Colors.black87,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                booking['description'] ??
                                    'No description provided',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Images: ${(booking['images'] != null && (booking['images'] as List).isNotEmpty) ? (booking['images'] as List).length : 'no'}',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Voice recording: ${booking['recording'] != null ? 'yes' : 'no'}',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Videos: ${(booking['videos'] != null && (booking['videos'] as List).isNotEmpty) ? (booking['videos'] as List).length : 'no'}',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Address : $location',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Name: $userName, Mobile: $userPhone',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _finishBooking(bookingId),
                                      icon: const Icon(
                                        Icons.done,
                                        color: Colors.white,
                                      ),
                                      label: const Text(
                                        'Mark Finished',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.call,
                                        color: Colors.green,
                                      ),
                                      onPressed: () async {
                                        final phone = booking['userPhone'];
                                        if (phone != null && phone.isNotEmpty) {
                                          final String url = 'tel:$phone';
                                          if (await canLaunch(url)) {
                                            await launch(url);
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Could not launch phone dialer',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.directions,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () async {
                                        final lat =
                                            booking['userLat'] ??
                                            booking['latitude'];
                                        final lng =
                                            booking['userLng'] ??
                                            booking['longitude'];
                                        if (lat == null || lng == null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Location not available',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        // Get agent's current location
                                        Position? agentPosition;
                                        try {
                                          LocationPermission permission =
                                              await Geolocator.checkPermission();
                                          if (permission ==
                                              LocationPermission.denied) {
                                            permission =
                                                await Geolocator.requestPermission();
                                            if (permission ==
                                                    LocationPermission.denied ||
                                                permission ==
                                                    LocationPermission
                                                        .deniedForever) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Location permissions are required for navigation',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                          }
                                          agentPosition =
                                              await Geolocator.getCurrentPosition(
                                                desiredAccuracy:
                                                    LocationAccuracy.high,
                                              );
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error getting current location: $e',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        // ignore: unnecessary_null_comparison
                                        if (agentPosition == null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Could not get current location',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        // Try Google Maps navigation intent
                                        final String mapsUrl =
                                            'google.navigation:q=$lat,$lng&saddr=${agentPosition.latitude},${agentPosition.longitude}&mode=d';
                                        final Uri mapsUri = Uri.parse(mapsUrl);
                                        if (await canLaunchUrl(mapsUri)) {
                                          await launchUrl(
                                            mapsUri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        } else {
                                          // Fallback to web URL
                                          final String webUrl =
                                              'https://www.google.com/maps/dir/?api=1&origin=${agentPosition.latitude},${agentPosition.longitude}&destination=$lat,$lng&travelmode=driving';
                                          final Uri webUri = Uri.parse(webUrl);
                                          if (await canLaunchUrl(webUri)) {
                                            await launchUrl(
                                              webUri,
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Could not launch maps app',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          DrawerHeader(
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(color: Colors.greenAccent.shade700),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_rounded,
                      size: 30,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _agentName ?? 'Agent User',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _agentPhoneNumber ?? 'N/A',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_rounded, color: Colors.green),
            title: const Text(
              'Home',
              style: TextStyle(fontFamily: 'Montserrat', fontSize: 16),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.book_online_rounded, color: Colors.green),
            title: const Text(
              'My Bookings',
              style: TextStyle(fontFamily: 'Montserrat', fontSize: 16),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AgentBookingsScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.chat_rounded, color: Colors.green),
            title: const Text(
              'Chats',
              style: TextStyle(fontFamily: 'Montserrat', fontSize: 16),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatsListScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.attach_money_rounded,
              color: Colors.green,
            ),
            title: const Text(
              'My Earnings',
              style: TextStyle(fontFamily: 'Montserrat', fontSize: 16),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AgentEarningsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_rounded, color: Colors.green),
            title: const Text(
              'Settings',
              style: TextStyle(fontFamily: 'Montserrat', fontSize: 16),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AgentSettingsScreen()),
              );
            },
          ),
          const Expanded(child: SizedBox()),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                color: Colors.redAccent,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showLogoutConfirmationDialog();
            },
          ),
        ],
      ),
    );
  }
}
