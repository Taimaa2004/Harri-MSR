import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../main.dart' show flutterLocalNotificationsPlugin;

import '../../../main.dart';

class BookMeetingScreen extends StatefulWidget {
  final DateTime selectedTime;
  final String roomId;

  const BookMeetingScreen({
    super.key,
    required this.selectedTime,
    required this.roomId,
  });

  @override
  _BookMeetingScreenState createState() => _BookMeetingScreenState();
}

class _BookMeetingScreenState extends State<BookMeetingScreen> {
  TextEditingController titleController = TextEditingController();
  TextEditingController notesController = TextEditingController();

  late DateTime selectedStartTime;
  late DateTime selectedEndTime;
  List<String> selectedMemberIds = [];
  String searchQuery = '';
  bool _membersExpanded = false;

  String recurrenceType = 'None';
  final List<String> recurrenceOptions = ['None', 'Daily', 'Weekly', 'Monthly'];
  DateTime? repeatUntil;

  final Map<int, String> weekDayLabels = {
    1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu',
    5: 'Fri', 6: 'Sat', 7: 'Sun',
  };
  List<int> selectedWeekDays = [];
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    selectedStartTime = widget.selectedTime;
    selectedEndTime = widget.selectedTime.add(const Duration(hours: 1));

    // Initialize notifications
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);

    flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  @override
  void dispose() {
    titleController.dispose();
    notesController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue.shade500),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
      ),
    );
  }

  void selectTime(BuildContext context, bool isStart) async {
    TimeOfDay initial = TimeOfDay.fromDateTime(isStart ? selectedStartTime : selectedEndTime);
    TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: initial);

    if (pickedTime != null && mounted) {
      DateTime base = isStart ? selectedStartTime : selectedEndTime;
      DateTime updated = DateTime(base.year, base.month, base.day, pickedTime.hour, pickedTime.minute);

      setState(() {
        if (isStart) {
          selectedStartTime = updated;
          if (!selectedEndTime.isAfter(updated)) {
            selectedEndTime = updated.add(const Duration(hours: 1));
          }
        } else {
          selectedEndTime = updated;
        }
      });
    }
  }

  Future<void> saveMeeting() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (titleController.text.trim().isEmpty) {
      _showSnack("Meeting title cannot be empty.");
      return;
    }

    if (recurrenceType == 'Weekly' && selectedWeekDays.isEmpty) {
      _showSnack("Please select at least one weekday.");
      return;
    }

    if (recurrenceType != 'None' && repeatUntil == null) {
      _showSnack("Please select a repeat end date.");
      return;
    }

    if (currentUser != null && !selectedMemberIds.contains(currentUser.uid)) {
      selectedMemberIds.add(currentUser.uid);
    }

    List<DateTime> startDates = _generateRecurrenceDates();

    for (final startDate in startDates) {
      final endDate = startDate.add(selectedEndTime.difference(selectedStartTime));

      if (await _isOverlapping(startDate, endDate)) {
        _showSnack("Meeting time overlaps with another meeting!");
        return;
      }

      // ✅ Save meeting in Firestore (lowercase "meetings")
      await firestore.collection('Meetings').add({
        'title': titleController.text.trim(),
        'notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        'start_time': Timestamp.fromDate(startDate),
        'end_time': Timestamp.fromDate(endDate),
        'room_id': widget.roomId,
        'users': selectedMemberIds,
        'creatorId': currentUser!.uid,
      });

      // ✅ Optional: Add in-app notification docs
      for (String userId in selectedMemberIds) {
        final message = userId == currentUser?.uid
            ? 'You created a meeting: "${titleController.text.trim()}" at ${startDate.toLocal().toString().substring(0, 16)}'
            : 'You have been invited to: "${titleController.text.trim()}"';

        // Add Firestore notification
        await firestore.collection('notifications').add({
          'userId': userId,
          'title': titleController.text.trim(),
          'body': notesController.text.trim().isNotEmpty
              ? '$message\nNotes: ${notesController.text.trim()}'
              : message,
          'senderName': currentUser?.email ?? "Unknown",
          'timestamp': Timestamp.now(),
          'isRead': false,
        });

        // Show push notification locally
        await flutterLocalNotificationsPlugin.show(
          0,
          titleController.text.trim(),
          message,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'meeting_channel',
              'Meetings',
              channelDescription: 'Notifications for new meetings',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    }

    if (mounted) Navigator.pop(context);
  }

  Future<bool> _isOverlapping(DateTime startDate, DateTime endDate) async {
    QuerySnapshot existingMeetings = await FirebaseFirestore.instance
        .collection('Meetings')
        .where('room_id', isEqualTo: widget.roomId)
        .get();

    return existingMeetings.docs.any((doc) {
      var data = doc.data() as Map<String, dynamic>;
      DateTime existingStart = (data['start_time'] as Timestamp).toDate();
      DateTime existingEnd = (data['end_time'] as Timestamp).toDate();
      return startDate.isBefore(existingEnd) && endDate.isAfter(existingStart);
    });
  }

  List<DateTime> _generateRecurrenceDates() {
    List<DateTime> startDates = [];

    if (recurrenceType == 'None') {
      startDates.add(selectedStartTime);
    } else if (recurrenceType == 'Daily' && repeatUntil != null) {
      DateTime current = selectedStartTime;
      while (current.isBefore(repeatUntil!.add(const Duration(days: 1)))) {
        startDates.add(current);
        current = current.add(const Duration(days: 1));
      }
    } else if (recurrenceType == 'Weekly' && repeatUntil != null) {
      DateTime current = selectedStartTime;
      while (current.isBefore(repeatUntil!.add(const Duration(days: 1)))) {
        if (selectedWeekDays.contains(current.weekday)) {
          startDates.add(DateTime(current.year, current.month, current.day,
              selectedStartTime.hour, selectedStartTime.minute));
        }
        current = current.add(const Duration(days: 1));
      }
    } else if (recurrenceType == 'Monthly' && repeatUntil != null) {
      DateTime current = selectedStartTime;
      while (current.isBefore(repeatUntil!.add(const Duration(days: 1)))) {
        startDates.add(current);
        current = DateTime(current.year, current.month + 1, current.day,
            current.hour, current.minute);
      }
    }

    return startDates..sort();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<List<Map<String, dynamic>>> getTeamMembers() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('team').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'first_name': data['first_name'] ?? 'No Name',
          'last_name': data['last_name'] ?? 'No Name',
          'email': data['email'] ?? '',
        };
      }).toList();
    } catch (e) {
      print("🔥 Error fetching team members: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF007AFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Book Meeting",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: getTeamMembers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var teamMembers = snapshot.data as List<Map<String, dynamic>>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildCard([
                  TextField(controller: titleController, decoration: _inputDecoration("Meeting Title", Icons.title)),
                  const SizedBox(height: 12),
                ]),
                const SizedBox(height: 16),

                _buildCard([
                  ListTile(
                    leading: const Icon(Icons.access_time, color: Colors.blue),
                    title: Text("Start Time: ${TimeOfDay.fromDateTime(selectedStartTime).format(context)}"),
                    onTap: () => selectTime(context, true),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.timelapse, color: Colors.blue),
                    title: Text("End Time: ${TimeOfDay.fromDateTime(selectedEndTime).format(context)}"),
                    onTap: () => selectTime(context, false),
                  ),
                ]),
                const SizedBox(height: 16),

                _buildCard([
                  ListTile(
                    leading: const Icon(Icons.group, color: Colors.blue),
                    title: const Text("Select Members"),
                    trailing: Icon(_membersExpanded ? Icons.expand_less : Icons.expand_more),
                    onTap: () => setState(() => _membersExpanded = !_membersExpanded),
                  ),
                  if (_membersExpanded) ...[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: _inputDecoration("Search members...", Icons.search),
                        onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: ListView(
                        children: teamMembers
                            .where((member) =>
                        member['first_name'].toLowerCase().contains(searchQuery) ||
                            member['last_name'].toLowerCase().contains(searchQuery))
                            .map((member) {
                          final fullName = '${member['first_name']} ${member['last_name']}';

                          return CheckboxListTile(
                            title: Text(fullName),
                            subtitle: Text(member['email']),
                            value: selectedMemberIds.contains(member['id']),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  selectedMemberIds.add(member['id']);
                                } else {
                                  selectedMemberIds.remove(member['id']);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 16),

                _buildCard([
                  DropdownButtonFormField<String>(
                    value: recurrenceType,
                    decoration: _inputDecoration("Recurrence", Icons.repeat),
                    items: recurrenceOptions.map((option) =>
                        DropdownMenuItem<String>(value: option, child: Text(option))
                    ).toList(),
                    onChanged: (val) {
                      setState(() {
                        recurrenceType = val!;
                        if (recurrenceType != 'Weekly') {
                          selectedWeekDays.clear();
                        }
                      });
                    },
                  ),
                  if (recurrenceType == 'Weekly') ...[
                    const SizedBox(height: 8),
                    const Text("Select Weekdays:"),
                    Wrap(
                      spacing: 8.0,
                      children: weekDayLabels.entries.map((entry) {
                        final day = entry.key;
                        final label = entry.value;
                        final isSelected = selectedWeekDays.contains(day);

                        return FilterChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedWeekDays.add(day);
                              } else {
                                selectedWeekDays.remove(day);
                              }
                            });
                          },

                        );

                      }).toList(),
                    ),
                  ],
                  if (recurrenceType != 'None')
                    ListTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.blue),
                      title: Text(repeatUntil != null
                          ? 'Repeat Until: ${repeatUntil!.toLocal().toString().split(' ')[0]}'
                          : 'Select End Date'),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedStartTime,
                          firstDate: selectedStartTime,
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => repeatUntil = picked);
                        }
                      },
                    ),
                ]),
                const SizedBox(height: 24),

                _buildCard([
                  TextField(
                    controller: notesController,
                    decoration: _inputDecoration("Notes (optional)", Icons.note_alt),
                    maxLines: 4,
                    minLines: 3,
                    style: const TextStyle(fontSize: 15),
                  ),
                ]),

                const SizedBox(height: 24),


                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white
                  ),
                  onPressed: saveMeeting,
                  label: const Text("Save Meeting", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.blue.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}
