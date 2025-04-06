import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class BookingScreen extends StatefulWidget {
  final String roomId; // Change from roomName to roomId
  final String meetingTitle;

  const BookingScreen({super.key, required this.roomId, required this.meetingTitle});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay? endTime;
  int? capacity;
  String? location, status;
  List<String>? equipment;
  bool loading = true;
  String bookingSummary = '';

  @override
  void initState() {
    super.initState();
    fetchRoomDetails();
  }

  Future<void> fetchRoomDetails() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('meeting_rooms')
          .doc(widget.roomId) // Fetch room by ID
          .get();

      if (snapshot.exists) {
        final room = snapshot.data()!;
        setState(() {
          capacity = room['capacity'];
          equipment = List<String>.from(room['equipments'] ?? []);
          location = room['location'];
          status = room['room_status'];
          loading = false;
        });
      } else {
        print("No room found with ID: ${widget.roomId}");
        setState(() {
          capacity = 0;
          equipment = [];
          location = "Not available";
          status = "No status";
          loading = false;
        });
      }
    } catch (e) {
      print("Error fetching room details: $e");
      setState(() {
        capacity = 0;
        equipment = [];
        location = "Error occurred";
        status = "Unavailable";
        loading = false;
      });
    }
  }


  Future<void> bookMeeting() async {
    final start = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      startTime.hour,
      startTime.minute,
    );

    final pickedEnd = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute),
    );
    if (pickedEnd == null) return;

    final end = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      pickedEnd.hour,
      pickedEnd.minute,
    );

    if (end.isBefore(start)) {
      showMessage("End time must be after start time.");
      return;
    }

    try {
      final meetings = await FirebaseFirestore.instance
          .collection('Meetings')
          .where('room_id', isEqualTo: widget.roomId) // Use room ID for checking
          .get();

      for (var meeting in meetings.docs) {
        final mStart = (meeting['start_time'] as Timestamp).toDate();
        final mEnd = (meeting['end_time'] as Timestamp).toDate();
        if (start.isBefore(mEnd) && end.isAfter(mStart)) {
          showMessage("Time conflict! Try another time.");
          return;
        }
      }
      await FirebaseFirestore.instance.collection('Meetings').add({
        'room_id': widget.roomId,
        'start_time': Timestamp.fromDate(start),
        'end_time': Timestamp.fromDate(end),
        'title': widget.meetingTitle,
      });


      setState(() {
        endTime = pickedEnd;
        bookingSummary =
        'Room ID: ${widget.roomId}\nDate: ${selectedDate.toLocal().toString().split(' ')[0]}\nStart: ${startTime.format(context)}\nEnd: ${endTime!.format(context) }\n title: ${widget.meetingTitle}';
      });
print( widget.meetingTitle);
      showMessage(" Meeting booked successfully!");
    } catch (e) {
      print(" Booking failed: $e");
      showMessage(" Failed to book the meeting.");
    }
  }

  void showMessage(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
        ],
      ),
    );
  }

  Widget roomDetailItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('$label: ${value ?? "Not available"}', style: TextStyle(fontSize: 16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
     //   title: Text('Book Room: ${widget.roomName}'),
        backgroundColor: Colors.indigo,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Room Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              roomDetailItem('Location', location),
              roomDetailItem('Capacity', capacity),
              roomDetailItem('Status', status),
              roomDetailItem(' Equipment', equipment?.join(', ') ?? "None"),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.access_time,color:Colors.white),
                label: Text("Pick End Time & Book"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 48),
                ),
                onPressed: bookMeeting,
              ),
              if (bookingSummary.isNotEmpty) ...[
                SizedBox(height: 20),
                Text('Meeting Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(bookingSummary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
