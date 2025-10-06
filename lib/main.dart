import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:genie_on_call/screens/user/home_screen.dart';
import 'package:genie_on_call/screens/login_screen.dart';
import 'package:genie_on_call/screens/role_selection_screen.dart';
import 'package:genie_on_call/screens/agent/agent_home_screen.dart';
import 'package:provider/provider.dart';
import 'package:genie_on_call/providers/theme_provider.dart';

// final FirebaseAuth _auth = FirebaseAuth.instance;
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void initializeLocalNotification() {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> _setupFCM() async {
  NotificationSettings settings = await FirebaseMessaging.instance
      .requestPermission(alert: true, badge: true, sound: true);

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              "high_importance_channel",
              "High Importance Notifications",
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true,
              channelShowBadge: true,
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(message);
    });
  } else {
    debugPrint('User declined or has not accepted notifications.');
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    // Token refreshed, but not saving to avoid overwriting
  });
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
  // _showFlutterNotification(message);
}

void initState() {
  initializeLocalNotification();
  _setupFCM();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  initState();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

final ThemeData _lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  primaryColor: Colors.green,
  scaffoldBackgroundColor: const Color(0xFFF8FAFC),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Color(0xDE000000), fontFamily: 'Montserrat'),
    bodyMedium: TextStyle(color: Color(0x99000000), fontFamily: 'Montserrat'),
  ),
  fontFamily: 'Montserrat',
);

final ThemeData _darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: Colors.green,
  scaffoldBackgroundColor: const Color(0xFF303030),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF212121),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF424242),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
    bodyMedium: TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
  ),
  fontFamily: 'Montserrat',
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Genie On Call',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.isDarkMode ? _darkTheme : _lightTheme,
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasData) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(snapshot.data!.uid)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (userSnapshot.hasData && userSnapshot.data!.exists) {
                        final data =
                            userSnapshot.data!.data() as Map<String, dynamic>;
                        final role = data['role'];
                        if (role == 'agent') {
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('agents')
                                .doc(snapshot.data!.uid)
                                .get(),
                            builder: (context, agentSnapshot) {
                              if (agentSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (agentSnapshot.hasData &&
                                  agentSnapshot.data!.exists) {
                                return const AgentHomeScreen();
                              } else {
                                return const RoleSelectionScreen();
                              }
                            },
                          );
                        } else if (role == 'user') {
                          return const HomeScreen();
                        } else {
                          return const RoleSelectionScreen();
                        }
                      } else {
                        return const RoleSelectionScreen();
                      }
                    },
                  );
                }
                return const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
