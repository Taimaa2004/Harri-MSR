import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation_project/Screens/Rooms/show_Rooms_Details_Screen.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'Book Meeting/Calendar_Booking_Screen.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'EditMeetingScreen.dart';

class MeetingListPage extends StatefulWidget {
  final String roomId;
  final String roomName;

  const MeetingListPage(
      {super.key, required this.roomId, required this.roomName});

  @override
  _MeetingListPageState createState() => _MeetingListPageState();
}

class _MeetingListPageState extends State<MeetingListPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<Appointment> meetings = [];
  StreamSubscription<QuerySnapshot>? _meetingSub;


  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    fetchMeetings();

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);
    flutterLocalNotificationsPlugin.initialize(initSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        flutterLocalNotificationsPlugin.show(
          message.hashCode,
          message.notification!.title,
          message.notification!.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'meeting_channel',
              'Meetings',
              channelDescription: 'Notifications for meetings',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }


  @override
  void dispose() {
    _meetingSub?.cancel();
    super.dispose();
  }
  Future<void> sendLocalNotification(String title, String body) async {
    await flutterLocalNotificationsPlugin.show(
      title.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meeting_channel',
          'Meetings',
          channelDescription: 'Notifications for meetings',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }


  void fetchMeetings() {
    _meetingSub = firestore
        .collection('Meetings')
        .where('room_id', isEqualTo: widget.roomId)
        .snapshots()
        .listen((snapshot) {
      List<Appointment> fetchedMeetings = [];

      // Handle added/modified/removed documents
      for (var change in snapshot.docChanges) {
        var data = change.doc.data() as Map<String, dynamic>;
        DateTime? startTime = (data['start_time'] as Timestamp?)?.toDate();
        DateTime? endTime = (data['end_time'] as Timestamp?)?.toDate();
        String meetingName = data['title'] ?? 'Untitled Meeting';

        if (change.type == DocumentChangeType.removed) {
          // Notify users about deletion
          sendLocalNotification(
              'Meeting Cancelled', 'The meeting "$meetingName" was deleted.');
        }

        if (startTime != null && endTime != null && change.type != DocumentChangeType.removed) {
          fetchedMeetings.add(Appointment(
            startTime: startTime,
            endTime: endTime,
            subject: meetingName,
            color: Colors.blueAccent,
            id: change.doc.id,
          ));
        }
      }

      setState(() {
        meetings = fetchedMeetings;
      });
    });
  }

  void onTap(CalendarTapDetails details) {
    if (details.targetElement == CalendarElement.appointment) {
      Appointment appointment = details.appointments!.first;
      showMeetingDetails(appointment);
    } else {
      DateTime selectedTime = details.date!;
      bookMeeting(selectedTime);
    }
  }

  void bookMeeting(DateTime selectedTime) async {
    bool isOverlapping = meetings.any((meeting) =>
    (selectedTime.isAfter(meeting.startTime) &&
        selectedTime.isBefore(meeting.endTime)) ||
        selectedTime.isAtSameMomentAs(meeting.startTime));

    if (isOverlapping) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This time slot is already booked!")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookMeetingScreen(
            selectedTime: selectedTime, roomId: widget.roomId),
      ),
    );
  }

  Future<void> deleteMeeting(String meetingId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (meetingId.isEmpty) return;

    try {
      final docRef = firestore.collection('Meetings').doc(meetingId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) return;

      final data = docSnap.data() as Map<String, dynamic>;
      final String meetingTitle = data['title'] ?? "Untitled Meeting";

      // Notify all users subscribed
      final notifyUsersSnap = await docRef.collection('notifyUsers').get();
      for (var userDoc in notifyUsersSnap.docs) {
        final userId = userDoc['userId'];
        if (userId != currentUser?.uid) {
          // Add Firestore notification
          await firestore.collection('notifications').add({
            'userId': userId,
            'title': 'Meeting Cancelled',
            'body': 'The meeting "$meetingTitle" has been cancelled.',
            'senderName': currentUser?.displayName ?? 'System',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });

          // Send local notification
          await flutterLocalNotificationsPlugin.show(
            userDoc.hashCode,
            'Meeting Cancelled',
            'The meeting "$meetingTitle" has been cancelled.',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'meeting_channel',
                'Meetings',
                channelDescription: 'Notifications for meetings',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );

          // Optional: Send FCM message to device tokens here
          // You need to store each user's FCM token in Firestore
        }
      }

      // Delete meeting
      await docRef.delete();
    } catch (e) {
      print('Error deleting meeting: $e');
    }
  }

  Future<void> subscribeNotifyMe(String meetingId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final subDoc = firestore
        .collection('Meetings')
        .doc(meetingId)
        .collection('notifyUsers')
        .doc(currentUser.uid);

    final exists = (await subDoc.get()).exists;
    if (!exists) {
      await subDoc.set({'userId': currentUser.uid, 'timestamp': FieldValue.serverTimestamp()});

      // Show local notification
      await flutterLocalNotificationsPlugin.show(
        currentUser.uid.hashCode,
        'Subscribed',
        'You will be notified if the meeting is cancelled.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'meeting_channel',
            'Meetings',
            channelDescription: 'Notifications for meetings',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  void showMeetingDetails(Appointment appointment) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    final idRaw = appointment.id;
    final String meetingId = idRaw?.toString() ?? '';

    if (meetingId.isEmpty) {
      _showSnack('Invalid meeting id (appointment has no id).');
      return;
    }

    DocumentSnapshot meetingDoc;
    try {
      meetingDoc = await firestore.collection('Meetings').doc(meetingId).get();
    } catch (e) {
      print('Error fetching meeting doc for details: $e');
      _showSnack('Failed to load meeting details.');
      return;
    }

    if (!meetingDoc.exists) {
      _showSnack('Meeting no longer exists.');
      return;
    }

    final data = meetingDoc.data() as Map<String, dynamic>;
    final creatorId = data['creatorId'] ?? '';
    final isCreator = currentUser != null && creatorId == currentUser.uid;

    String startDate = DateFormat('yyyy-MM-dd').format(appointment.startTime);
    String startTime = DateFormat('HH:mm').format(appointment.startTime);
    String endTime = DateFormat('HH:mm').format(appointment.endTime);
    String notes = data['notes'] ?? '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 12,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event, size: 30, color: Colors.blueAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        appointment.subject,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const Divider(height: 20, thickness: 1.5),
                Text("Date: $startDate", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text("Start Time: $startTime", style: const TextStyle(fontSize: 16)),
                Text("End Time: $endTime", style: const TextStyle(fontSize: 16)),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text("Notes:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(notes, style: const TextStyle(fontSize: 16)),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isCreator) ...[
                      TextButton.icon(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        label: const Text('Edit', style: TextStyle(color: Colors.blue)),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditMeetingScreen(
                                meetingId: meetingId,
                                roomId: widget.roomId,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              title: const Text('Delete Meeting'),
                              content: const Text('Are you sure you want to delete this meeting?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            Navigator.pop(context);
                            await deleteMeeting(meetingId);
                          }
                        },
                      ),
                    ] else ...[
                      TextButton.icon(
                        icon: const Icon(Icons.notifications_active, color: Colors.blue),
                        label: const Text('Notify Me', style: TextStyle(color: Colors.blue)),
                        onPressed: () async {
                          Navigator.pop(context);
                          await subscribeNotifyMe(meetingId);
                        },
                      ),
                    ],
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );

  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.blue.shade700,
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 16))),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.roomName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        toolbarHeight: 80,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ToggleSwitch(
              minWidth: 200,
              fontSize: 20,
              totalSwitches: 2,
              labels: const ['Meetings', 'Details'],
              onToggle: (index) {
                if (index == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Showroomsdetails(
                          roomId: widget.roomId,
                        )),
                  );
                }
              },
            ),
            Expanded(
              child: SfCalendar(
                view: CalendarView.day,
                showNavigationArrow: true,
                showWeekNumber: true,
                dataSource: MeetingDataSource(meetings),
                onTap: onTap,
                timeSlotViewSettings: const TimeSlotViewSettings(
                  timeTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                todayHighlightColor: Colors.blueAccent,
                selectionDecoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent, width: 1.5),
                ),
                appointmentTextStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}
