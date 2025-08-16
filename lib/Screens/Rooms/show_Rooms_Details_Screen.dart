import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class Showroomsdetails extends StatefulWidget {
  final String roomId;

  const Showroomsdetails({super.key, required this.roomId});

  @override
  State<Showroomsdetails> createState() => _ShowroomsdetailsState();
}

class _ShowroomsdetailsState extends State<Showroomsdetails> {
  int capacity = 0;
  List<String> equipment = [];
  String location = '';
  String status = 'Available';
  String roomName = '';
  bool loading = true;

  StreamSubscription<QuerySnapshot>? meetingSubscription;

  @override
  void initState() {
    super.initState();
    fetchRoomDetails();
    setupMeetingListener();
  }

  @override
  void dispose() {
    meetingSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchRoomDetails() async {
    try {
      final roomSnapshot = await FirebaseFirestore.instance
          .collection('meeting_rooms')
          .doc(widget.roomId)
          .get();

      if (roomSnapshot.exists) {
        final room = roomSnapshot.data()!;

        int roomCapacity = room['capacity'] ?? 0;
        List<String> roomEquipments = List<String>.from(room['equipments'] ?? []);
        String roomLocation = room['location'] ?? 'Unknown';
        String roomTitle = room['name'] ?? 'Unnamed Room';

        setState(() {
          capacity = roomCapacity;
          equipment = roomEquipments;
          location = roomLocation;
          roomName = roomTitle;
          loading = false;
        });
      } else {
        setState(() {
          capacity = 0;
          equipment = [];
          location = "Not available";
          status = "No status";
          roomName = "Unnamed Room";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        capacity = 0;
        equipment = [];
        location = "Error occurred";
        status = "Unavailable";
        roomName = "Unnamed Room";
        loading = false;
      });
    }
  }

  void setupMeetingListener() {
    final now = DateTime.now();

    // Listen for meetings that are currently ongoing
    meetingSubscription = FirebaseFirestore.instance
        .collection('Meetings')
        .where('room_id', isEqualTo: widget.roomId)
    // where start_time <= now and end_time >= now
        .where('start_time', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .where('end_time', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .snapshots()
        .listen((snapshot) {
      bool occupied = snapshot.docs.isNotEmpty;
      setState(() {
        status = occupied ? "Occupied" : "Available";
      });
    });
  }

  Widget _buildInfoCard(
      {required IconData icon,
        required String title,
        required String subtitle,
        Color? iconColor}) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 5,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor?.withOpacity(0.15) ?? Colors.blue.withOpacity(0.15),
          child: Icon(icon, size: 28, color: iconColor ?? Colors.blue),
        ),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  Widget _buildNotes(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "📌 $text",
        style: TextStyle(color: Colors.blue.shade900, fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Room Details"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(
              icon: Icons.people,
              title: "Capacity",
              subtitle: "$capacity people",
              iconColor: Colors.orange,
            ),
            _buildInfoCard(
              icon: Icons.location_on,
              title: "Location",
              subtitle: location,
              iconColor: Colors.green,
            ),
            _buildInfoCard(
              icon: Icons.info_outline,
              title: "Status",
              subtitle: status,
              iconColor: status == "Occupied" ? Colors.red : Colors.blue,
            ),
            Card(
              color: Colors.white.withOpacity(0.9),
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 5,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.devices, color: Colors.purple),
                        const SizedBox(width: 10),
                        const Text(
                          "Equipment",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...equipment.map(
                          (item) => Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: Colors.green),
                            const SizedBox(width: 6),
                            Text(item, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 5,
              shadowColor: Colors.black26,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Room QR Code',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    QrImageView(
                      data: jsonEncode({
                        'name': roomName,
                        'location': location,
                        'capacity': capacity,
                        'status': status,
                      }),
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
