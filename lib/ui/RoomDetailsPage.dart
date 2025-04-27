import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation_project/ui/showRoomsDetails.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'BookMeetingPage.dart';
import 'package:toggle_switch/toggle_switch.dart';

class MeetingListPage extends StatefulWidget {
  final String roomId;
  final String roomName;

  const MeetingListPage(
      {super.key, required this.roomId, required this.roomName});

  @override
  _MeetingListPageState createState() => _MeetingListPageState();
}

class _MeetingListPageState extends State<MeetingListPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<Appointment> meetings = [];

  @override
  void initState() {
    super.initState();
    fetchMeetings();
  }

  void fetchMeetings() {
    firestore
        .collection('Meetings')
        .where('room_id', isEqualTo: widget.roomId)
        .snapshots()
        .listen((snapshot) {
      List<Appointment> fetchedMeetings = [];

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime? startTime = (data['start_time'] as Timestamp?)?.toDate();
        DateTime? endTime = (data['end_time'] as Timestamp?)?.toDate();
        String meetingName = data['title'] ?? 'Untitled Meeting';

        if (startTime != null && endTime != null) {
          fetchedMeetings.add(Appointment(
            startTime: startTime,
            endTime: endTime,
            subject: meetingName,
            color: Colors.blueAccent,
            id: doc.id, // Store meeting ID for editing
          ));
        }
      }

      setState(() {
        meetings = fetchedMeetings;
      });
    });
  }

  void onTap(CalendarTapDetails details) {
    if (details.targetElement == CalendarElement.appointment) {
      Appointment appointment = details.appointments!.first;
      showMeetingDetails(appointment);
    } else {
      DateTime selectedTime = details.date!;
      bookMeeting(selectedTime);
    }
  }

  void showMeetingDetails(Appointment appointment) {
    String startDate = DateFormat('yyyy-MM-dd').format(appointment.startTime);
    String startTime = DateFormat('HH:mm').format(appointment.startTime);
    String endTime = DateFormat('HH:mm').format(appointment.endTime);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appointment.subject),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Date: $startDate "),
            Text("Start Time: $startTime"),
            Text("End Time: $endTime"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  void bookMeeting(DateTime selectedTime) async {
    bool isOverlapping = meetings.any((meeting) =>
        (selectedTime.isAfter(meeting.startTime) &&
            selectedTime.isBefore(meeting.endTime)) ||
        selectedTime.isAtSameMomentAs(meeting.startTime));

    if (isOverlapping) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("This time slot is already booked!")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookMeetingScreen(
            selectedTime: selectedTime, roomId: widget.roomId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.roomName,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        toolbarHeight: 80,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ToggleSwitch(
              minWidth: 200,
              fontSize: 20,
              totalSwitches: 2,
              labels: ['Meetings', 'Details'],
              onToggle: (index) {
                if (index == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Showroomsdetails(
                              roomId: widget.roomId,
                            )),
                  );
                }
              },
            ),
            Expanded(
              child: SfCalendar(
                view: CalendarView.day,
                showNavigationArrow: true,
                showWeekNumber: true,
                dataSource: MeetingDataSource(meetings),
                onTap: onTap,
                timeSlotViewSettings: TimeSlotViewSettings(
                  timeTextStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500),
                ),
                todayHighlightColor: Colors.blueAccent,
                selectionDecoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent, width: 1.5),
                ),
                appointmentTextStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}
