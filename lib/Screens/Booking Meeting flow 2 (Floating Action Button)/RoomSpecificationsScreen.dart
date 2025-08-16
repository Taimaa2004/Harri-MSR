import 'package:flutter/material.dart';

class RoomSpecificationsScreen extends StatefulWidget {
  final Map<String, dynamic> selectedSpecs;

  const RoomSpecificationsScreen({super.key, required this.selectedSpecs});

  @override
  State<RoomSpecificationsScreen> createState() => _RoomSpecificationsScreenState();
}

class _RoomSpecificationsScreenState extends State<RoomSpecificationsScreen> {
  late Map<String, dynamic> specs;
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  final List<String> allEquipments = ["Screen", "Projector", "Whiteboard", "Speaker"];

  @override
  void initState() {
    super.initState();
    specs = Map.from(widget.selectedSpecs);

    capacityController.text = (specs["capacity"] ?? "").toString();
    locationController.text = specs["location"] ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Room Specifications")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: capacityController,
            decoration: const InputDecoration(labelText: "Minimum Capacity"),
            keyboardType: TextInputType.number,
            onChanged: (val) => specs["capacity"] = int.tryParse(val) ?? 0,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: locationController,
            decoration: const InputDecoration(labelText: "Location (e.g. floor3)"),
            onChanged: (val) => specs["location"] = val,
          ),
          const SizedBox(height: 20),
          const Text("Required Equipments", style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: allEquipments.map((eq) {
              final selected = (specs["equipments"] ?? []).contains(eq);
              return FilterChip(
                label: Text(eq),
                selected: selected,
                onSelected: (val) {
                  setState(() {
                    final eqList = List<String>.from(specs["equipments"] ?? []);
                    if (val) {
                      eqList.add(eq);
                    } else {
                      eqList.remove(eq);
                    }
                    specs["equipments"] = eqList;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, specs); // return selected filters
            },
            child: const Text("Save Specifications"),
          ),
        ],
      ),
    );
  }
}
