import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Calendar_view_Screen.dart';

class RoomListPage extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

   RoomListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Available Rooms",
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ),
      body:
      StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('meeting_rooms').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No rooms available"));
          }
          var rooms = snapshot.data!.docs;
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              var room = rooms[index].data() as Map<String, dynamic>? ?? {};
              String roomName = room['name'] ?? 'Unnamed Room';
              return ListTile(
                title: Text(roomName),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MeetingListPage(
                          roomId: rooms[index].id, roomName: roomName),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
