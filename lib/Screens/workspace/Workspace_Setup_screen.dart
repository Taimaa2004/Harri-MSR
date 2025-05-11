import 'package:flutter/material.dart';

class WorkspaceSetupPage extends StatelessWidget {
  final TextEditingController meetingOfficeCountController;

  const WorkspaceSetupPage({
    super.key,
    required this.meetingOfficeCountController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Workspace Setup",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0A66C2)),
            ),
            const SizedBox(height: 8),
            const Text(
              "Let's set up the physical structure of your workspace.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.meeting_room_outlined, color: Colors.blueAccent),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "How many meeting rooms are there in your workspace?",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: meetingOfficeCountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "e.g., 3",
                      filled: true,
                      prefixIcon: const Icon(Icons.format_list_numbered, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
