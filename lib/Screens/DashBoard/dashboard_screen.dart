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

  @override
  void initState() {
    super.initState();
    fetchMeetings();
    capitalizeUserName();
    fetchUserRole();
    listenToNotificationCount();
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
        QuerySnapshot meetingSnapshot = await FirebaseFirestore.instance
            .collection('Meetings')
            .where('users', arrayContains: user.uid)
            .orderBy('start_time')
            .get();

        final seenRecurringIds = <String>{};
        final List<QueryDocumentSnapshot> filteredMeetings = [];

        for (final doc in meetingSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;

          if (data.containsKey('recurring_id')) {
            final recurringId = data['recurring_id'];

            if (!seenRecurringIds.contains(recurringId)) {
              filteredMeetings.add(doc);
              seenRecurringIds.add(recurringId);
            }
          } else {
            // Single (non-recurring) meeting
            filteredMeetings.add(doc);
          }
        }

        QuerySnapshot roomSnapshot =
        await FirebaseFirestore.instance.collection('meeting_rooms').get();

        setState(() {
          meetingDocuments = filteredMeetings;
          roomDocuments = roomSnapshot.docs;
        });
      }
    } catch (e) {
      print("Error fetching meetings: $e");
    }
  }

  void fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('team')
        .doc(user.uid)
        .get();

    if (!mounted || !doc.exists) return;

    setState(() {
      userRole = doc['role'] ?? '';
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

        // 👇 Only show notifications when on Dashboard page (index 0)
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
                      MaterialPageRoute(builder: (context) => const NotificationPage()),
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
      return  AnalyticsDashboard();
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

    return ListView.builder(
      itemCount: meetingDocuments.length,
      itemBuilder: (context, index) {
        var meeting = meetingDocuments[index];
        var meetingData = meeting.data() as Map<String, dynamic>;

        var meetingName = meetingData['title'] ?? 'Unnamed Meeting';
        DateTime? startTime = (meeting['start_time'] as Timestamp?)?.toDate();
        DateTime? endTime = (meeting['end_time'] as Timestamp?)?.toDate();
        String startFormatted =
        startTime != null ? DateFormat('HH:mm').format(startTime) : 'No Start Time';
        String endFormatted =
        endTime != null ? DateFormat('HH:mm').format(endTime) : 'No End Time';
        String dateFormatted =
        startTime != null ? DateFormat('yyyy-MM-dd').format(startTime) : 'No Date';

        var roomId = meetingData['room_id'];
        QueryDocumentSnapshot? roomData;

        for (var room in roomDocuments) {
          if (room.id == roomId) {
            roomData = room;
            break;
          }
        }

        String roomName = 'Unknown Room';
        String roomLocation = 'Not Available';

        if (roomData != null) {
          var data = roomData.data() as Map<String, dynamic>;
          roomName = data.containsKey('name') ? data['name'] : 'Unknown Room';
          roomLocation = data.containsKey('location') ? data['location'] : 'Not Available';
        }


        return Card(
          surfaceTintColor: Colors.cyan,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text(meetingName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Start Time: $startFormatted'),
                Text('End Time: $endFormatted'),
                Text('Meeting Date: $dateFormatted'),
                Text('Room: $roomName',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
      },
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
