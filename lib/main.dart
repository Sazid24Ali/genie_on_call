import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:genie_on_call/providers/theme_provider.dart';
import 'package:genie_on_call/providers/locale_provider.dart';
import 'package:genie_on_call/services/translation_service.dart';
import 'package:genie_on_call/screens/login_screen.dart';
import 'package:genie_on_call/screens/role_selection_screen.dart';
import 'package:genie_on_call/screens/user/home_screen.dart';
import 'package:genie_on_call/screens/agent/agent_home_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void initializeLocalNotification() {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );
  flutterLocalNotificationsPlugin.initialize(initSettings);
}

Future<void> _setupFCM() async {
  try {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final android = message.notification?.android;
        if (notification != null && android != null) {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'High Importance Notifications',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (message.notification != null)
          debugPrint(message.notification.toString());
      });
    }
  } catch (e) {
    debugPrint('FCM setup failed: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Notifications & FCM
  initializeLocalNotification();
  await _setupFCM();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final firestore = FirebaseFirestore.instance;
  final translationService = TranslationService();

  runApp(
    MultiProvider(
      providers: [
        Provider<TranslationService>.value(value: translationService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          title: 'Genie On Call',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.isDarkMode
              ? ThemeData.dark()
              : ThemeData.light(),
          locale: localeProvider.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            Locale('te'),
            Locale.fromSubtags(languageCode: 'hi', scriptCode: 'Latn'),
            Locale.fromSubtags(languageCode: 'te', scriptCode: 'Latn'),
          ],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
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
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      final data =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      final role = data['role'];
                      if (role == 'agent') return const AgentHomeScreen();
                      if (role == 'user') return const HomeScreen();
                      return const RoleSelectionScreen();
                    }
                    return const RoleSelectionScreen();
                  },
                );
              }
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
