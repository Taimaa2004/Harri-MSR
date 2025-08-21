import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'Screens/DashBoard/notification_screen.dart';
import 'Screens/Drawer/Preference/theme_provider.dart';
import 'Screens/Splash/splash_screen.dart';
import 'Users/taimaajweles/StudioProjects/graduation_project/lib/API/firebase_api.dart';
import 'firebase_options.dart';

// ------------------------------
// Initialize local notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      payload: 'notificationPage', // <-- add payload here
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
      // Handle notification tap
      if (details.payload == 'notificationPage') {
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (_) => const NotificationPage()),
        );
      }
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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // <-- add this block inside the listener
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
          payload: message.data['type'] ?? 'notificationPage', // <-- handle deleted meetings here
        );
      }
    });

    // On notification tap (foreground or background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final type = message.data['type'];
      if (type == 'deleted_meeting') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const NotificationPage(deleted: true)),
        );
      } else {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const NotificationPage()),
        );
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        final type = message.data['type'];
        if (type == 'deleted_meeting') {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const NotificationPage(deleted: true)),
          );
        } else {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const NotificationPage()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      navigatorKey: navigatorKey, // <-- needed for navigation
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
