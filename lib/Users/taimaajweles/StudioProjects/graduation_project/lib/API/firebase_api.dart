import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseApi {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Initialize notifications
  Future<void> initNotifications() async {
    // Request permissions (iOS)
    await _messaging.requestPermission();

    // Save the token for the current user
    String? token = await _messaging.getToken();
    if (token != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'fcmToken': token}, SetOptions(merge: true));
      }
    }

    // Listen to token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'fcmToken': newToken}, SetOptions(merge: true));
      }
    });
  }

  // Send notification to multiple users
  Future<void> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
  }) async {
    final firestore = FirebaseFirestore.instance;
    for (String userId in userIds) {
      final doc = await firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data()?['fcmToken'] != null) {
        String token = doc.data()?['fcmToken'];
        // Use your FCM backend or Cloud Function to send the message
        // Here, just storing it in Firestore for demo purposes
        await firestore.collection('notifications').add({
          'userId': userId,
          'title': title,
          'body': body,
          'senderName': 'System',
          'timestamp': Timestamp.now(),
          'isRead': false,
        });
      }
    }
  }
}
