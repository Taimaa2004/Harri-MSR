import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation_project/Screens/DashBoard/dashboard_screen.dart';
import 'Working_Hours_Screen.dart';
import 'Workspace_Intro_Screen.dart';
import 'Workspace_Setup_screen.dart';

class CreateWorkspace extends StatefulWidget {
  const CreateWorkspace({super.key});

  @override
  State<CreateWorkspace> createState() => _StepperPageState();
}

class _StepperPageState extends State<CreateWorkspace> {
  final PageController pageController = PageController();
  int currentStep = 0;

  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController workspaceSummaryController = TextEditingController();
  final TextEditingController meetingOfficeCountController = TextEditingController();

  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool isSubmitting = false;

  List<Widget> get pages => [
    WorkspaceIntroPage(
      companyNameController: companyNameController,
      workspaceSummaryController: workspaceSummaryController,
    ),
    WorkspaceSetupPage(
      meetingOfficeCountController: meetingOfficeCountController,
    ),
    WorkingHoursPage(
      startTime: startTime,
      endTime: endTime,
      onStartTimePicked: (pickedStart) {
        setState(() {
          startTime = pickedStart;
        });
      },
      onEndTimePicked: (pickedEnd) {
        setState(() {
          endTime = pickedEnd;
        });
      },
    ),
  ];

  void goToNext() {
    if (currentStep < pages.length - 1) {
      setState(() {
        currentStep++;
      });
      pageController.animateToPage(
        currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void goToPrevious() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      pageController.animateToPage(
        currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> submitWorkspaceData() async {
    if (isSubmitting) return; // prevent duplicate submission

    if (companyNameController.text.isEmpty ||
        workspaceSummaryController.text.isEmpty ||
        meetingOfficeCountController.text.isEmpty ||
        startTime == null ||
        endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('workspaces').add({
        'companyName': companyNameController.text.trim(),
        'summary': workspaceSummaryController.text.trim(),
        'meetingRooms': int.tryParse(meetingOfficeCountController.text.trim()) ?? 0,
        'startTime': '${startTime!.hour}:${startTime!.minute}',
        'endTime': '${endTime!.hour}:${endTime!.minute}',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Workspace created successfully"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error saving workspace: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving workspace: $e"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        toolbarHeight: 90,
        title: const Text(
          'Create Workspace',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: pages,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentStep > 0)
                  ElevatedButton(
                    onPressed: isSubmitting ? null : goToPrevious,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Back'),
                  )
                else
                  const SizedBox(width: 80),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                    if (currentStep == pages.length - 1) {
                      submitWorkspaceData();
                    } else {
                      goToNext();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    isSubmitting
                        ? 'Submitting...'
                        : currentStep == pages.length - 1
                        ? 'Finish'
                        : 'Next',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
