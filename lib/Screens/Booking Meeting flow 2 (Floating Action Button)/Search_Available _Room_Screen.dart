import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'RoomSpecificationsScreen.dart';
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

  Map<String, dynamic> selectedSpecs = {
    "capacity": 0,
    "location": "",
    "equipments": []
  };

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

    final hasSpecs = selectedSpecs["capacity"] != 0 ||
        (selectedSpecs["equipments"] as List).isNotEmpty ||
        selectedSpecs["location"].toString().isNotEmpty;

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

    if (availableRoomIds.isEmpty) {
      setState(() {
        isLoading = false;
      });
      _showPopup("No rooms available at the selected time.");
      return;
    }

    try {
      final roomSnapshot = await _firestore
          .collection('meeting_rooms')
          .where(FieldPath.documentId, whereIn: availableRoomIds)
          .get();

      final matchingDocs = roomSnapshot.docs.where((doc) {
        // Safe checks
        int roomCapacity = 0;
        if (doc.data().containsKey('capacity')) {
          final rawCapacity = doc['capacity'];
          if (rawCapacity is int) {
            roomCapacity = rawCapacity;
          } else if (rawCapacity is String) {
            roomCapacity = int.tryParse(rawCapacity) ?? 0;
          }
        }

        String roomLocation = '';
        if (doc.data().containsKey('location')) {
          roomLocation = doc['location'] ?? '';
        }

        List roomEquipments = [];
        if (doc.data().containsKey('equipments')) {
          final rawEquipments = doc['equipments'];
          if (rawEquipments is List) {
            roomEquipments = rawEquipments;
          } else if (rawEquipments is String) {
            roomEquipments = [rawEquipments];
          }
        }

        if (!hasSpecs) return true;

        final capacityOk = roomCapacity >= (selectedSpecs['capacity'] ?? 0);
        final locationOk = selectedSpecs['location'].toString().isEmpty ||
            roomLocation.toLowerCase() ==
                selectedSpecs['location'].toString().toLowerCase();

        List selectedEquipments = [];
        final rawSelectedEquipments = selectedSpecs['equipments'];
        if (rawSelectedEquipments is List) {
          selectedEquipments = rawSelectedEquipments;
        } else if (rawSelectedEquipments is String &&
            rawSelectedEquipments.isNotEmpty) {
          selectedEquipments = [rawSelectedEquipments];
        }

        final equipmentsOk =
        selectedEquipments.every((eq) => roomEquipments.contains(eq));

        return capacityOk && locationOk && equipmentsOk;
      }).toList();

      setState(() {
        availableRoomDocs = matchingDocs;
        isLoading = false;
      });

      if (matchingDocs.isEmpty) {
        _showPopup("No rooms match the selected specifications.");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching rooms: $e");
      _showPopup("Error fetching rooms. Please try again.");
    }
  }

  Future<List<String>> getAvailableRooms(DateTime selectedStartDateTime) async {
    final bookedRooms = <String>[];
    final selectedEndDateTime = selectedStartDateTime.add(const Duration(hours: 1));

    try {
      final meetingsSnapshot = await _firestore.collection('Meetings').get();
      print("Meetings count: ${meetingsSnapshot.docs.length}");

      for (var meeting in meetingsSnapshot.docs) {
        final data = meeting.data();

        // Skip meetings without necessary fields
        if (!data.containsKey('room_id') ||
            !data.containsKey('start_time') ||
            !data.containsKey('end_time')) {
          print("⚠️ Skipping meeting without required fields: ${meeting.id}");
          continue;
        }

        final mRoomId = data['room_id'].toString();

        final startTimestamp = data['start_time'];
        final endTimestamp = data['end_time'];

        if (startTimestamp is! Timestamp || endTimestamp is! Timestamp) {
          print("⚠️ Skipping meeting with invalid timestamps: ${meeting.id}");
          continue;
        }

        final mStart = startTimestamp.toDate().toUtc();
        final mEnd = endTimestamp.toDate().toUtc();

        final selectedStartUtc = selectedStartDateTime.toUtc();
        final selectedEndUtc = selectedEndDateTime.toUtc();

        print("Checking $mRoomId: $mStart → $mEnd");

        // Check for overlap
        if (selectedStartUtc.isBefore(mEnd) && selectedEndUtc.isAfter(mStart)) {
          bookedRooms.add(mRoomId);
          print("❌ Room $mRoomId marked as booked");
        }
      }

      final roomsSnapshot = await _firestore.collection('meeting_rooms').get();
      final allRooms = roomsSnapshot.docs.map((doc) => doc.id.toString()).toList();
      print("All rooms: $allRooms");
      print("Booked rooms: $bookedRooms");

      final available = allRooms.where((roomId) => !bookedRooms.contains(roomId)).toList();
      print("✅ Available rooms: $available");

      return available;
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
    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (availableRoomDocs.isEmpty) {
      return const Center(
        child: Text(
          "No rooms available for selected time and specs.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: availableRoomDocs.map((roomDoc) {
        final roomName = roomDoc['name'] ?? "Unknown";
        final roomId = roomDoc.id;
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: const Icon(Icons.meeting_room, color: Colors.blueAccent),
            title: Text(roomName),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookMeetingScreen(
                  roomId: roomId,
                  selectedTime: DateTime(
                    selectedDate!.year,
                    selectedDate!.month,
                    selectedDate!.day,
                    startTime!.hour,
                    startTime!.minute,
                  ),
                ),
              ),
            ),

          ),
        );
      }).toList(),
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
            _buildSelectionCard(
              icon: Icons.settings,
              label: "Room Specifications",
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RoomSpecificationsScreen(selectedSpecs: selectedSpecs),
                  ),
                );
                if (result != null) {
                  setState(() {
                    selectedSpecs = Map<String, dynamic>.from(result);
                  });
                }
              },
            ),

            if (selectedSpecs.isNotEmpty &&
                (selectedSpecs["capacity"] != 0 ||
                    (selectedSpecs["equipments"] as List).isNotEmpty ||
                    selectedSpecs["location"].toString().isNotEmpty))
              Card(
                elevation: 2,
                color: Colors.grey[100],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Selected Specifications",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      if (selectedSpecs["capacity"] != 0)
                        Text("Capacity: ${selectedSpecs["capacity"]}"),
                      if (selectedSpecs["location"].toString().isNotEmpty)
                        Text("Location: ${selectedSpecs["location"]}"),
                      if ((selectedSpecs["equipments"] as List).isNotEmpty)
                        Text(
                            "Equipments: ${(selectedSpecs["equipments"] as List).join(", ")}"),
                    ],
                  ),
                ),
              ),

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
