import 'package:flutter/material.dart';

class WorkingHoursPage extends StatelessWidget {
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Function(TimeOfDay) onStartTimePicked;
  final Function(TimeOfDay) onEndTimePicked;

  const WorkingHoursPage({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.onStartTimePicked,
    required this.onEndTimePicked,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Working Hours",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0A66C2)),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.access_time_filled, color: Colors.blueAccent),
              SizedBox(width: 10),
              Expanded(
                child: Text("Set your working hours", style: TextStyle(fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text("Start Time", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: startTime ?? TimeOfDay.now(),
              );
              if (pickedTime != null) {
                onStartTimePicked(pickedTime);
              }
            },
            child: _buildTimeSelector(startTime?.format(context) ?? 'Select start time'),
          ),
          const SizedBox(height: 30),
          const Text("End Time", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: endTime ?? TimeOfDay.now(),
              );
              if (pickedTime != null) {
                onEndTimePicked(pickedTime);
              }
            },
            child: _buildTimeSelector(endTime?.format(context) ?? 'Select end time'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}
