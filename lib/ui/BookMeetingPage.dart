import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookMeetingScreen extends StatefulWidget {
  final DateTime selectedTime;
  final String roomId;

  const BookMeetingScreen({
    super.key,
    required this.selectedTime,
    required this.roomId,
  });

  @override
  _BookMeetingScreenState createState() => _BookMeetingScreenState();
}

class _BookMeetingScreenState extends State<BookMeetingScreen> {
  TextEditingController titleController = TextEditingController();
  late DateTime selectedStartTime;
  late DateTime selectedEndTime;

  @override
  void initState() {
    super.initState();
    selectedStartTime = widget.selectedTime;
    selectedEndTime = widget.selectedTime.add(Duration(hours: 1));
  }

  void saveMeeting() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    QuerySnapshot existingMeetings = await firestore
        .collection('Meetings')
        .where('room_id', isEqualTo: widget.roomId)
        .get();

    bool isOverlapping = existingMeetings.docs.any((doc) {
      var data = doc.data() as Map<String, dynamic>;
      DateTime startTime = (data['start_time'] as Timestamp).toDate();
      DateTime endTime = (data['end_time'] as Timestamp).toDate();

      return (selectedStartTime.isBefore(endTime) && selectedEndTime.isAfter(startTime));
    });

    if (isOverlapping) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Meeting time overlaps with another meeting!")),
      );
      return;
    }

    await firestore.collection('Meetings').add({
      'title': titleController.text,
      'start_time': Timestamp.fromDate(selectedStartTime),
      'end_time': Timestamp.fromDate(selectedEndTime),
      'room_id': widget.roomId,
    });

    Navigator.pop(context);
  }

  void selectTime(BuildContext context, bool isStart) async {
    TimeOfDay initial = TimeOfDay.fromDateTime(isStart ? selectedStartTime : selectedEndTime);
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (pickedTime != null) {
      setState(() {
        DateTime base = isStart ? selectedStartTime : selectedEndTime;
        DateTime updated = DateTime(
          base.year,
          base.month,
          base.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (isStart) {
          selectedStartTime = updated;
          if (!selectedEndTime.isAfter(updated)) {
            selectedEndTime = updated.add(Duration(hours: 1));
          }
        } else {
          selectedEndTime = updated;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Book Meeting")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "Meeting Title"),
            ),
            ListTile(
              title: Text(
                "Start Time: ${TimeOfDay.fromDateTime(selectedStartTime).format(context)}",
              ),
              trailing: Icon(Icons.access_time),
              onTap: () => selectTime(context, true),
            ),
            ListTile(
              title: Text(
                "End Time: ${TimeOfDay.fromDateTime(selectedEndTime).format(context)}",
              ),
              trailing: Icon(Icons.access_time),
              onTap: () => selectTime(context, false),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveMeeting,
              child: Text("Save Meeting"),
            ),
          ],
        ),
      ),
    );
  }
}
