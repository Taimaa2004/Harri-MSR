import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation_project/Screens/Profile/profile_Screen.dart';
import 'package:graduation_project/Screens/Team/team_Screen.dart';
import 'package:intl/intl.dart';
import '../Admin Dashboad/Admin_Dashboard.dart';
import '../Booking Meeting flow 2 (Floating Action Button)/Search_Available _Room_Screen.dart';
import '../Rooms/Calendar_view_Screen.dart';
import '../Rooms/Rooms_List_Screen.dart';
import '../Drawer/drawer_Section.dart';
import 'notification_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentPageIndex = 0;
  String firstName = "";
  String userRole = "";
  List<QueryDocumentSnapshot> meetingDocuments = [];
  List<QueryDocumentSnapshot> roomDocuments = [];
  DateTime? _activeFilterDate; // null = show today + upcoming

  @override
  void initState() {
    super.initState();
    fetchMeetings();
    capitalizeUserName();
    fetchUserRole();
    listenToNotificationCount();
  }

  // ---------- Helpers ----------
  bool _isRecurring(Map<String, dynamic> data) {
    try {
      // Support multiple possible schemas
      final recurringId = (data['recurring_id'] ??
          data['recurrence_id'] ??
          data['series_id'] ??
          '')
          .toString();

      final boolFlags = (data['is_recurring'] == true) ||
          (data['isRecurring'] == true) ||
          (data['recurring'] == true) ||
          (data['repeat'] == true);

      final hasRuleLike =
          data['recurrence'] != null || data['rrule'] != null || data['rule'] != null;

      final result =
          boolFlags || hasRuleLike || (recurringId.isNotEmpty && recurringId != 'null');

      return result;
    } catch (_) {
      return false;
    }
  }

  int unreadNotificationCount = 0;
  void listenToNotificationCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        unreadNotificationCount = snapshot.docs.length;
      });
    });
  }

  void fetchMeetings() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final meetingSnapshot = await FirebaseFirestore.instance
            .collection('Meetings')
            .where('users', arrayContains: user.uid)
            .orderBy('start_time')
            .get();

        final roomSnapshot =
        await FirebaseFirestore.instance.collection('meeting_rooms').get();

        setState(() {
          meetingDocuments = meetingSnapshot.docs;
          roomDocuments = roomSnapshot.docs;
        });

        // Debug counts (optional)
        int recurringCount = 0;
        for (final d in meetingSnapshot.docs) {
          final m = d.data() as Map<String, dynamic>;
          if (_isRecurring(m)) recurringCount++;
        }
        // This helps verify detection in your console
        // You can remove these prints later.
        // ignore: avoid_print
        print(
            'Fetched meetings: total=${meetingSnapshot.docs.length}, recurring=$recurringCount');
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error fetching meetings: $e");
    }
  }

  void fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
    await FirebaseFirestore.instance.collection('team').doc(user.uid).get();

    if (!mounted || !doc.exists) return;

    setState(() {
      userRole = doc['role'] ?? '';
      // ignore: avoid_print
      print(userRole);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        title: Text(
          getPageTitle(currentPageIndex),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        toolbarHeight: 120,
        centerTitle: true,

        // Only on Dashboard page
        actions: currentPageIndex == 0
            ? [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationPage(),
                      ),
                    );
                  },
                ),
                if (unreadNotificationCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unreadNotificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ]
            : null,
      ),
      drawer: currentPageIndex == 0 ? drawerSection(context) : null,
      floatingActionButton: currentPageIndex == 0
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMeeting1()),
          );
        },
        backgroundColor: Colors.blue[200],
        child: const Icon(Icons.add, size: 30, color: Colors.indigo),
      )
          : null,
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.blue[200],
        selectedIndex: currentPageIndex,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(
              icon: Icon(Icons.meeting_room_sharp), label: 'Rooms'),
          const NavigationDestination(
              icon: Icon(Icons.people_rounded), label: 'Team'),
          const NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          if (userRole == 'Admin')
            const NavigationDestination(
                icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ],
      ),
      body: getCurrentScreen(),
    );
  }

  Widget getCurrentScreen() {
    if (userRole.toLowerCase() == 'admin' && currentPageIndex == 4) {
      return AnalyticsDashboard();
    }

    switch (currentPageIndex) {
      case 0:
        return meetings();
      case 1:
        return RoomListPage();
      case 2:
        return Teamscreen();
      case 3:
        return ProfileScreen();
      default:
        return meetings();
    }
  }

  String getPageTitle(int index) {
    if (userRole == 'admin' && index == 4) return "Admin";

    switch (index) {
      case 0:
        return "Hello $firstName 👋";
      case 1:
        return "Rooms";
      case 2:
        return "Team";
      case 3:
        return "Profile";
      default:
        return "Dashboard";
    }
  }

  Widget meetings() {
    if (meetingDocuments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.event_busy, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No meetings available",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54),
            ),
            SizedBox(height: 8),
            Text(
              "Schedule a new meeting to see it here.",
              style: TextStyle(fontSize: 16, color: Colors.black45),
            ),
          ],
        ),
      );
    }

    final today = DateTime.now();

    // Filter only today's meetings
    final todayMeetings = meetingDocuments.where((meeting) {
      final data = meeting.data() as Map<String, dynamic>;
      final startTime = (data['start_time'] as Timestamp?)?.toDate();
      if (startTime == null) return false;
      return startTime.year == today.year &&
          startTime.month == today.month &&
          startTime.day == today.day;
    }).toList();

    // Sort by start time
    todayMeetings.sort((a, b) {
      final aTime = (a.data() as Map<String, dynamic>)['start_time'] as Timestamp?;
      final bTime = (b.data() as Map<String, dynamic>)['start_time'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return aTime.toDate().compareTo(bTime.toDate());
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "Meetings of Today",
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Today's meetings cards
        if (todayMeetings.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "No meetings scheduled for today.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ...todayMeetings.map((meeting) {
          final data = meeting.data() as Map<String, dynamic>;
          final startTime = (data['start_time'] as Timestamp?)?.toDate();
          final endTime = (data['end_time'] as Timestamp?)?.toDate();
          final roomId = data['room_id'];

          QueryDocumentSnapshot? roomData;
          for (final room in roomDocuments) {
            if (room.id == roomId) {
              roomData = room;
              break;
            }
          }

          String roomName = 'Unknown Room';
          String roomLocation = 'Not Available';
          if (roomData != null) {
            final r = roomData.data() as Map<String, dynamic>?;
            if (r != null) {
              roomName = r['name'] ?? 'Unknown Room';
              roomLocation = r['location'] ?? 'Not Available';
            }
          }

          final recurring = _isRecurring(data);
          final meetingName = data['title'] ?? 'Unnamed Meeting';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Row(
                children: [
                  if (recurring) ...[
                    const Icon(Icons.repeat, color: Colors.blue, size: 18),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      meetingName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start: ${startTime != null ? DateFormat('HH:mm').format(startTime) : '--'}'),
                  Text('End: ${endTime != null ? DateFormat('HH:mm').format(endTime) : '--'}'),
                  Text('Room: $roomName'),
                  Text('Location: $roomLocation'),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MeetingListPage(roomId: roomId, roomName: roomName),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ],
    );
  }

  void capitalizeUserName() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    setState(() {
      firstName = user.email!
          .split("@")[0]
          .replaceAll(RegExp(r'[\._-]'), ' ')
          .split(' ')
          .map((word) =>
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
          .join(' ');
    });
  }
}
