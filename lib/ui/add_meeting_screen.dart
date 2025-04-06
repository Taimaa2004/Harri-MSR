import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMeetingScreen extends StatefulWidget {
  final DateTime selectedTime;

  const AddMeetingScreen({super.key, required this.selectedTime});

  @override
  _AddMeetingScreenState createState() => _AddMeetingScreenState();
}

class _AddMeetingScreenState extends State<AddMeetingScreen> {
  final TextEditingController _titleController = TextEditingController();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();

  void _saveMeeting() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a meeting title")));
      return;
    }

    DateTime startDateTime = DateTime(
      widget.selectedTime.year, widget.selectedTime.month, widget.selectedTime.day,
      _startTime.hour, _startTime.minute,
    );

    DateTime endDateTime = DateTime(
      widget.selectedTime.year, widget.selectedTime.month, widget.selectedTime.day,
      _endTime.hour, _endTime.minute,
    );

    await FirebaseFirestore.instance.collection('Meetings').add({
      'title': _titleController.text,
      'start_time': Timestamp.fromDate(startDateTime),
      'end_time': Timestamp.fromDate(endDateTime),
    });

    Navigator.pop(context); // 🔹 Go back to Calendar Screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Meeting")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Meeting Title"),
            ),
            ListTile(
              title: Text("Start Time: ${_startTime.format(context)}"),
              onTap: () async {
                TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: _startTime);
                if (pickedTime != null) setState(() => _startTime = pickedTime);
              },
            ),
            ListTile(
              title: Text("End Time: ${_endTime.format(context)}"),
              onTap: () async {
                TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: _endTime);
                if (pickedTime != null) setState(() => _endTime = pickedTime);
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveMeeting,
              child: Text("Save Meeting"),
            ),
          ],
        ),
      ),
    );
  }
}
