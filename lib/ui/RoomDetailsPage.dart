import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MeetingListPage extends StatelessWidget {
  final String roomId;
  final String roomName;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  MeetingListPage({super.key, required this.roomId, required this.roomName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$roomName - Meetings Details"),
        backgroundColor: Colors.blue[600],
        toolbarHeight: 90,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('Meetings')
            .where('room_id', isEqualTo: roomId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No meetings available"));
          }
          var meetings = snapshot.data!.docs;
          return ListView.builder(
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              var meeting =
                  meetings[index].data() as Map<String, dynamic>? ?? {};
              String meetingName =
                  meeting['Meeting_name'] ?? 'Untitled Meeting';
              DateTime? startTime =
                  (meeting['start_time'] as Timestamp?)?.toDate();
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

              return Card(
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meetingName,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Date: $dateFormatted",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Start: $startFormatted",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Text(
                            "End: $endFormatted",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
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
