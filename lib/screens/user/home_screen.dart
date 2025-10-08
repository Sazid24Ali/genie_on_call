import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import Firebase Messaging
import 'user_bookings_screen.dart';
import 'service_details_screen.dart';
import 'settings_screen.dart';
import 'package:genie_on_call/screens/login_screen.dart'; // Import LoginScreen for logout navigation
import 'package:genie_on_call/screens/chat_screen.dart'; // Import ChatScreen
import 'package:genie_on_call/widgets/floating_chat_button.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/language_selector.dart';

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userName;
  String? _userPhoneNumber;

  bool _isInitialDataFetched = false;

  @override
  void initState() {
    super.initState();
    _setupFCM(); // Call FCM setup here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialDataFetched || ModalRoute.of(context)?.isCurrent == true) {
      _fetchUserData();
      _isInitialDataFetched = true;
    }
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          if (mounted) {
            setState(() {
              _userName = userDoc['name'];
              _userPhoneNumber = user.phoneNumber;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _userName = null;
              _userPhoneNumber = user.phoneNumber;
            });
          }
        }
      } catch (e) {
        print("Error fetching user name: $e");
        if (mounted) {
          setState(() {
            _userName = null;
            _userPhoneNumber = user.phoneNumber;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _userName = null;
          _userPhoneNumber = null;
        });
      }
    }
  }

  // --- FCM Methods Start ---
  Future<void> _setupFCM() async {
    // Request permission for notifications
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

    // Get the FCM token
    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $token");

    // Save the token to Firestore
    if (token != null && _auth.currentUser != null) {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("FCM Token saved to Firestore for user: ${_auth.currentUser!.uid}");
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print(
          'Message also contained a notification: ${message.notification!.title} - ${message.notification!.body}',
        );
        // Display a local notification or a SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.notification!.title ?? 'New Notification',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.blueAccent,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                // Optionally navigate to a specific screen based on message.data
                // For example, if message.data contains a 'bookingId'
                // Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailsScreen(bookingId: message.data['bookingId'])));
              },
            ),
          ),
        );
      }
    });

    // Handle when a user taps on a notification and the app is opened from background/terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      print('Message data: ${message.data}');
      // You can navigate to a specific screen here based on the notification data
      // For example:
      // if (message.data['screen'] == 'bookings') {
      //   Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(phoneNumber: _userPhoneNumber!)));
      // }
    });

    // Handle initial message when the app is opened from a terminated state by tapping a notification
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      print(
        'App opened from terminated state by notification: ${initialMessage.data}',
      );
      // Handle navigation based on initialMessage.data
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
            onPressed: () =>
                Navigator.of(dialogContext).pop(), // Dismiss dialog
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Montserrat', color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop(); // Dismiss dialog
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
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).appTitle,
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
        actions: [LanguageSelector()],
      ),
      drawer: _buildDrawer(context), // Call the drawer builder
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('services').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.black87,
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context).noServicesAvailable,
                style: TextStyle(
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.black87,
                ),
              ),
            );
          }

          final services = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              itemCount: services.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final service = services[index].data() as Map<String, dynamic>;
                final serviceName = service['name'] ?? 'Unknown Service';
                final serviceIconName = service['icon'] ?? '';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ServiceDetailsScreen(serviceName: serviceName),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 4,
                    shadowColor: Colors.blueAccent.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blueAccent.withOpacity(
                              0.08,
                            ),
                            radius: 28,
                            child: Icon(
                              getIconData(serviceIconName),
                              size: 32,
                              color: Colors.blueAccent,
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
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: const FloatingChatButton(),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Drawer(
      child: Column(
        children: <Widget>[
          DrawerHeader(
            padding: EdgeInsets.zero, // Remove default padding
            decoration: const BoxDecoration(color: Colors.blueAccent),
            child: Center(
              // Center the content horizontally
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center content vertically
                crossAxisAlignment: CrossAxisAlignment
                    .center, // Center content horizontally within the column
                children: [
                  const CircleAvatar(
                    radius: 24, // Reduced size
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_rounded,
                      size: 30, // Reduced size
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _userName ?? loc.customer, // This will now update correctly
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _userPhoneNumber ??
                        loc.notProvided, // This will also update correctly
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
            leading: const Icon(Icons.home_rounded, color: Colors.blueAccent),
            title: Text(
              loc.home,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.black87,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.book_online_rounded,
              color: Colors.blueAccent,
            ),
            title: Text(
              loc.myBookings,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.black87,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserBookingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_rounded, color: Colors.greenAccent),
            title: Text(
              loc.chat,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.black87,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.blueAccent),
            title: Text(
              loc.language,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.black87,
              ),
            ),
            trailing: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return DropdownButton<String>(
                  value: themeProvider.languageKey,
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                    DropdownMenuItem(value: 'te', child: Text('Telugu')),
                    DropdownMenuItem(value: 'en-T', child: Text('Tenglish')),
                    DropdownMenuItem(value: 'en-H', child: Text('Hinglish')),
                  ],
                  onChanged: (String? newValue) async {
                    if (newValue == null) return;
                    final languageLabel = (newValue == 'en')
                        ? 'English'
                        : (newValue == 'hi')
                        ? 'Hindi'
                        : (newValue == 'te')
                        ? 'Telugu'
                        : (newValue == 'en-T')
                        ? 'Tenglish'
                        : 'Hinglish';
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(loc.languageChangeDialogTitle),
                        content: Text(
                          loc.languageChangeDialogContent(languageLabel),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: Text(loc.cancel),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: Text(loc.confirm),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) themeProvider.setLanguage(newValue);
                  },
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.black87,
                  ),
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.settings_rounded,
              color: Colors.blueAccent,
            ),
            title: Text(
              loc.settings,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.black87,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const Expanded(
            child: SizedBox(),
          ), // This will push the remaining content to the bottom
          const Divider(), // Add a divider for visual separation
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: Text(
              loc.logout,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                color: Colors.redAccent,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              _showLogoutConfirmationDialog(); // Call the logout dialog
            },
          ),
        ],
      ),
    );
  }
}
