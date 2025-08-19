import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'Screens/Drawer/Preference/theme_provider.dart';
import 'Screens/Splash/splash_screen.dart';
import 'Users/taimaajweles/StudioProjects/graduation_project/lib/API/firebase_api.dart';
import 'firebase_options.dart';

// ------------------------------
// Initialize local notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// ------------------------------
// Background message handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (message.notification != null) {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'meeting_channel',
      'Meetings',
      channelDescription: 'Notifications for meetings',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      message.notification!.title.hashCode,
      message.notification!.title,
      message.notification!.body,
      platformDetails,
    );
  }
}

// ------------------------------
// Initialize Local Notifications
Future<void> _initializeLocalNotifications() async {
  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
  InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (details) {
      // Handle notification tap (terminated app)
      print('Notification clicked: ${details.payload}');
    },
  );
}

// ------------------------------
// Main
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Init local notifications
  await _initializeLocalNotifications();

  // Init FCM from API wrapper
  await FirebaseApi().initNotifications();

  // Subscribe to topic "Meetings"
  FirebaseMessaging.instance.subscribeToTopic("Meetings");

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

// ------------------------------
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFCMListeners();
  }

  void _setupFCMListeners() {
    // Foreground messages
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
              'meeting_channel',
              'Meeting Notifications',
              channelDescription: 'All meeting notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // When app is opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification tapped: ${message.notification?.title}");
    });

    // Check if app launched by notification (terminated)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print("App opened from terminated state by notification: ${message.notification?.title}");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
