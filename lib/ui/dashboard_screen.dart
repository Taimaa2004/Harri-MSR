import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation_project/ui/profileScreen.dart';
import 'package:graduation_project/ui/teamScreen.dart';
import 'package:intl/intl.dart';
import 'RoomDetailsPage.dart';
import 'RoomsListPage.dart';
import 'drawerSection.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentPageIndex = 0;
  String firstName = "";
  List<QueryDocumentSnapshot> meetingDocuments = []; // To store meeting data
  List<QueryDocumentSnapshot> roomDocuments = []; // To store room data

  @override
  void initState() {
    super.initState();
    fetchMeetings();
    capitalizeUserName();
  }

  void fetchMeetings() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot meetingSnapshot = await FirebaseFirestore.instance
            .collection('Meetings')
            .where('users', arrayContains: user.uid)
            .get();
        QuerySnapshot roomSnapshot =
            await FirebaseFirestore.instance.collection('meeting_rooms').get();
        setState(() {
          meetingDocuments = meetingSnapshot.docs;
          roomDocuments = roomSnapshot.docs;
        });
      }
    } catch (e) {
      print("Error fetching meetings: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        title: Text(
          getPageTitle(currentPageIndex),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        toolbarHeight: 120,
        centerTitle: true,
      ),
      drawer: currentPageIndex == 0 ? drawerSection(context) : null,
      floatingActionButton: currentPageIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // Handle button action
              },
              backgroundColor: Colors.blue[200],
              child: Icon(Icons.add, size: 30, color: Colors.indigo),
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
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
              icon: Icon(Icons.meeting_room_sharp), label: 'Rooms'),
          NavigationDestination(
              icon: Icon(Icons.people_rounded), label: 'Team'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: getCurrentScreen(),
    );
  }

// Function to get the current screen widget
  Widget getCurrentScreen() {
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
          children: [
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

        var meetingName = meetingData['Meeting_name'] ?? 'Unnamed Meeting';
        DateTime? startTime = (meeting['start_time'] as Timestamp?)?.toDate();
        DateTime? endTime = (meeting['end_time'] as Timestamp?)?.toDate();
        String startFormatted = startTime != null
            ? DateFormat('HH:mm').format(startTime)
            : 'No Start Time';
        String endFormatted = endTime != null
            ? DateFormat('HH:mm').format(endTime)
            : 'No End Time';
        String dateFormatted = startTime != null
            ? DateFormat('yyyy-MM-dd').format(startTime)
            : 'No Date';

        var roomId = meetingData['room_id'];
        var roomData = roomDocuments.firstWhere(
          (room) => room.id == roomId,
        );

        var roomName = roomData != null
            ? roomData['name'] ?? 'Unknown Room'
            : 'Unknown Room';
        var roomLocation = roomData != null
            ? roomData['location'] ?? 'Not Available'
            : 'Not Available';

        return Card(
          surfaceTintColor: Colors.cyan,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text(meetingName,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Start Time: $startFormatted'),
                Text('End Time: $endFormatted'),
                Text('Meeting Date: $dateFormatted'),
                Text('Room: $roomName',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
