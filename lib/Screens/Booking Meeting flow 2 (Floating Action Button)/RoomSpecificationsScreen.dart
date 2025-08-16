import 'package:flutter/material.dart';

class RoomSpecificationsScreen extends StatefulWidget {
  final Map<String, dynamic> selectedSpecs;

  const RoomSpecificationsScreen({super.key, required this.selectedSpecs});

  @override
  State<RoomSpecificationsScreen> createState() => _RoomSpecificationsScreenState();
}

class _RoomSpecificationsScreenState extends State<RoomSpecificationsScreen> {
  late Map<String, dynamic> specs;

  final List<String> allLocations = ["Floor 5", "Floor 6"];
  final List<String> allEquipments = [
    "Screen",
    "Projector",
    "Whiteboard",
    "Speaker",
    "Charging Plug",
    "Microphone",
    "Video Conference"
  ];

  @override
  void initState() {
    super.initState();
    specs = Map.from(widget.selectedSpecs);

    // Initialize capacity
    specs["capacity"] = specs["capacity"] ?? 0;

    // Initialize location
    specs["location"] = allLocations.firstWhere(
          (loc) => loc.toLowerCase() == (specs["location"] ?? "").toLowerCase(),
      orElse: () => allLocations.first,
    );

    // Initialize equipments as a list
    if (specs["equipments"] is String) {
      // Convert comma-separated string to List<String>
      specs["equipments"] = (specs["equipments"] as String).split(',').map((e) => e.trim()).toList();
    } else if (specs["equipments"] is List) {
      specs["equipments"] = List<String>.from(specs["equipments"]);
    } else {
      specs["equipments"] = <String>[];
    }
  }

  void _incrementCapacity() => setState(() => specs["capacity"] = (specs["capacity"] ?? 0) + 1);

  void _decrementCapacity() {
    setState(() {
      if ((specs["capacity"] ?? 0) > 0) specs["capacity"] -= 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Room Specifications"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Capacity Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.blueAccent, size: 28),
                    const SizedBox(width: 12),
                    const Text("Capacity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.remove_circle_outline, size: 28), onPressed: _decrementCapacity),
                    Text(specs["capacity"].toString(), style: const TextStyle(fontSize: 18)),
                    IconButton(icon: const Icon(Icons.add_circle_outline, size: 28), onPressed: _incrementCapacity),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Location Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blueAccent, size: 28),
                    const SizedBox(width: 12),
                    const Text("Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    DropdownButton<String>(
                      value: specs["location"],
                      items: allLocations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
                      onChanged: (val) => setState(() { if (val != null) specs["location"] = val; }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Equipments
            const Text("Required Equipments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allEquipments.map((eq) {
                    final selected = (specs["equipments"] as List<String>).contains(eq);
                    return FilterChip(
                      label: Text(eq),
                      selected: selected,
                      selectedColor: Colors.blueAccent.withOpacity(0.3),
                      checkmarkColor: Colors.blueAccent,
                      onSelected: (val) {
                        setState(() {
                          final eqList = List<String>.from(specs["equipments"] as List<String>);
                          if (val) {
                            if (!eqList.contains(eq)) eqList.add(eq);
                          } else {
                            eqList.remove(eq);
                          }
                          specs["equipments"] = eqList;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.pop(context, specs),
                child: const Text("Save Specifications"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
