import 'package:flutter/material.dart';

class WorkspaceIntroPage extends StatelessWidget {
  final TextEditingController companyNameController;
  final TextEditingController workspaceSummaryController;

  const WorkspaceIntroPage({
    Key? key,
    required this.companyNameController,
    required this.workspaceSummaryController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create Your Workspace",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Tell us a bit about your company or team to personalize your experience.",
              style: TextStyle(fontSize: 16,),
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
                  const Row(
                    children: [
                      Icon(Icons.business, color: Colors.blueAccent),
                      SizedBox(width: 10),
                      Text(
                        "Company or Team Name",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: companyNameController,
                    decoration: InputDecoration(
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Row(
                    children: [
                      Icon(Icons.description, color: Colors.blueAccent),
                      SizedBox(width: 10),
                      Text(
                        "Workspace Summary",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: workspaceSummaryController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Center(
              child: Text(
                "You're one step closer to launching your workspace",
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
