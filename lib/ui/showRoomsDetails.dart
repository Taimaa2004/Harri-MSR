import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  String status = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchRoomDetails();
  }

  Future<void> fetchRoomDetails() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('meeting_rooms')
          .doc(widget.roomId)
          .get();

      if (snapshot.exists) {
        final room = snapshot.data()!;
        setState(() {
          capacity = room['capacity'] ?? 0;
          equipment = List<String>.from(room['equipments'] ?? []);
          location = room['location'] ?? 'Unknown';
          status = room['room_status'] ?? 'Unavailable';
          loading = false;
        });
      } else {
        setState(() {
          capacity = 0;
          equipment = [];
          location = "Not available";
          status = "No status";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        capacity = 0;
        equipment = [];
        location = "Error occurred";
        status = "Unavailable";
        loading = false;
      });
    }
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String subtitle}) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.blue[600]),
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Room Details"),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoCard(
              icon: Icons.people,
              title: "Capacity",
              subtitle: "$capacity people",
            ),
            _buildInfoCard(
              icon: Icons.location_on,
              title: "Location",
              subtitle: location,
            ),
            _buildInfoCard(
              icon: Icons.info_outline,
              title: "Status",
              subtitle: status,
            ),
            Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.devices, color: Colors.blue[600]),
                        SizedBox(width: 10),
                        Text(
                          "Equipment",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    ...equipment.map(
                          (item) => Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.check, size: 16, color: Colors.green),
                            SizedBox(width: 6),
                            Text(item, style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    )
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
