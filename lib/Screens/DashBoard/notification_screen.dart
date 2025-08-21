import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationPage extends StatefulWidget {
  final bool deleted;

  const NotificationPage({super.key, this.deleted = false});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.deleted ? "Deleted Meeting Notifications" : "Notifications",
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: widget.deleted
          ? const Center(
        child: Text(
          "This meeting was deleted.",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      )
          : currentUser == null
          ? const Center(child: Text("No user logged in"))
          : StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('notifications')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications found"));
          }

          final notifications = snapshot.data!.docs;

          // --- Group recurring notifications ---
          Map<String?, Map<String, dynamic>> grouped = {};
          for (var doc in notifications) {
            final data = doc.data() as Map<String, dynamic>;
            final recurrenceId = data['recurrenceId']; // nullable
            if (recurrenceId != null) {
              if (!grouped.containsKey(recurrenceId)) {
                grouped[recurrenceId] = data;
              }
            } else {
              grouped[doc.id] = data; // single notifications
            }
          }

          final groupedNotifications = grouped.values.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: groupedNotifications.length,
            itemBuilder: (context, index) {
              final data = groupedNotifications[index];
              final timestamp =
              (data['timestamp'] as Timestamp).toDate();
              final formattedTime =
              DateFormat('yyyy-MM-dd HH:mm').format(timestamp);
              final title = data['title'] ?? 'No title';
              final body = data['body'] ?? '';
              final isRead = data['isRead'] ?? false;
              final senderName = data['senderName'] ?? 'Unknown sender';
              final recurrenceType = data['recurrenceType'];

              // Add recurrence sign if recurring
              final titleWithRecurrence = recurrenceType != null
                  ? ' $title'
                  : title;

              return Card(
                color: isRead ? Colors.white : Colors.blue[50],
                child: ListTile(
                  leading: Icon(
                    isRead
                        ? Icons.notifications_none
                        : Icons.notifications,
                    color: isRead ? Colors.grey : Colors.blue,
                  ),
                  title: Text(
                    titleWithRecurrence,
                    style:
                    const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From: $senderName',
                        style:
                        const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      Text(body),
                      const SizedBox(height: 4),
                      Text(formattedTime,
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: isRead
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.check),
                    tooltip: 'Mark as read',
                    onPressed: () {
                      firestore
                          .collection('notifications')
                          .doc(data['id']) // ensure doc id exists
                          .update({'isRead': true});
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
