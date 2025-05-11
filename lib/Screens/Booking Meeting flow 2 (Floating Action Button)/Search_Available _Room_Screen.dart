import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Add_Meeting.dart';

class AddMeeting1 extends StatefulWidget {
  const AddMeeting1({super.key});

  @override
  State<AddMeeting1> createState() => _AddMeeting1State();
}

class _AddMeeting1State extends State<AddMeeting1> {
  DateTime? selectedDate;
  TimeOfDay? startTime;
  List<DocumentSnapshot> availableRoomDocs = [];
  bool isLoading = false;
  String meetingTitle = "";

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        startTime = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Select Time';
    return time.format(context);
  }

  Future<void> _searchAvailableRooms() async {
    if (selectedDate == null || startTime == null) {
      _showPopup("Please select both date and start time.");
      return;
    }

    setState(() {
      isLoading = true;
      availableRoomDocs.clear();
    });

    final selectedStartDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      startTime!.hour,
      startTime!.minute,
    );


    final availableRoomIds = await getAvailableRooms(selectedStartDateTime);

    final QuerySnapshot roomSnapshot =
    await _firestore.collection('meeting_rooms').get();

    final matchingDocs = roomSnapshot.docs
        .where((doc) => availableRoomIds.contains(doc.id))
        .toList();

    setState(() {
      availableRoomDocs = matchingDocs;
      isLoading = false;
    });
  }

  Future<List<String>> getAvailableRooms(DateTime selectedStartDateTime) async {
    final bookedRooms = <String>[];

    try {
      // Get all booked meetings
      final meetingsSnapshot = await _firestore.collection('Meetings').get();

      for (var meeting in meetingsSnapshot.docs) {
        final mRoomId = meeting['room_id'];
        final mStart = (meeting['start_time'] as Timestamp).toDate();
        final mEnd = (meeting['end_time'] as Timestamp).toDate();

        if (!selectedStartDateTime.isBefore(mStart) && !selectedStartDateTime.isAfter(mEnd)) {
          bookedRooms.add(mRoomId.toString());
        }
      }

      final roomsSnapshot = await _firestore.collection('meeting_rooms').get();
      final allRooms = roomsSnapshot.docs.map((doc) => doc.id.toString()).toList();

      final availableRooms = allRooms.where((roomId) => !bookedRooms.contains(roomId)).toList();
      return availableRooms;
    } catch (e) {
      print("Error fetching available rooms: $e");
      return [];
    }
  }

  void _showPopup(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  Widget _buildRoomList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (availableRoomDocs.isEmpty) {
      return const Center(
        child: Text("No rooms available for selected time.",
            style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Available Rooms:",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...availableRoomDocs.map((roomDoc) {
          final roomName = roomDoc['name'];
          final roomId = roomDoc.id;
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: const Icon(Icons.meeting_room, color: Colors.blueAccent),
              title: Text(roomName),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingScreen(
                    roomId: roomId,  // Passing the correct roomId
                    meetingTitle: meetingTitle,
                  ),
                ),
              ),
            ),
          );
        })
      ],
    );
  }

  Widget _buildSelectionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
            const Icon(Icons.edit, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showMeetingTitleDialog() async {
    final titleController = TextEditingController();

    await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter Meeting Title"),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: "Meeting Title"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                meetingTitle = titleController.text;
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Meeting"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Meeting Details",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildSelectionCard(
              icon: Icons.text_fields,
              label: meetingTitle.isEmpty ? "Meeting Title" : meetingTitle,
              onTap: _showMeetingTitleDialog,
            ),
            _buildSelectionCard(
              icon: Icons.calendar_today,
              label: _formatDate(selectedDate),
              onTap: _pickDate,
            ),
            _buildSelectionCard(
              icon: Icons.access_time,
              label: _formatTime(startTime),
              onTap: _pickStartTime,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _searchAvailableRooms,
                icon: const Icon(Icons.search),
                label: const Text("Search Available Rooms"),
              ),
            ),
            const SizedBox(height: 20),
            _buildRoomList(),
          ],
        ),
      ),
    );
  }
}
