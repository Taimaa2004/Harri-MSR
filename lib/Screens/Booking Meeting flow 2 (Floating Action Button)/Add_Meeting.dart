import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  final String roomId;

  const BookingScreen({
    super.key,
    required this.roomId,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime selectedStartTime = DateTime.now();
  DateTime selectedEndTime = DateTime.now().add(const Duration(hours: 1));
  List<String> selectedMemberIds = [];
  bool loading = true;
  String memberSearch = '';
  TextEditingController notesController = TextEditingController();
  TextEditingController titleController = TextEditingController(); // Meeting title controller

  String? roomName;
  int? capacity;
  String? location, status;
  List<String>? equipment;
  String bookingSummary = '';

  String recurrenceType = 'None';
  final List<String> recurrenceOptions = ['None', 'Daily', 'Weekly', 'Monthly'];
  DateTime? repeatUntil;
  final Map<int, String> weekDayLabels = {
    1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'
  };
  List<int> selectedWeekDays = [];

  @override
  void initState() {
    super.initState();
    fetchRoomDetails();
  }

  @override
  void dispose() {
    notesController.dispose();
    titleController.dispose();
    super.dispose();
  }

  Future<void> fetchRoomDetails() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('meeting_rooms')
          .doc(widget.roomId)
          .get();
      if (snap.exists) {
        final room = snap.data()!;
        setState(() {
          roomName = room['name'] ?? "Unnamed Room";
          capacity = room['capacity'];
          equipment = List<String>.from(room['equipments'] ?? []);
          location = room['location'];
          status = room['room_status'];
          loading = false;
        });
      } else {
        setState(() {
          roomName = "Unknown Room";
          capacity = 0;
          equipment = [];
          location = "N/A";
          status = "N/A";
          loading = false;
        });
      }
    } catch (_) {
      setState(() {
        roomName = "Error loading room";
        capacity = 0;
        equipment = [];
        location = "Error";
        status = "Error";
        loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> getTeamMembers() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('team').get();
      return snap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'first_name': data['first_name'] ?? '',
          'last_name': data['last_name'] ?? '',
          'email': data['email'] ?? '',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMeeting() async {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return showMessage("No user logged in.");

    final meetingTitle = titleController.text.trim();
    if (meetingTitle.isEmpty) return showMessage("Please enter a meeting title.");

    if (!selectedMemberIds.contains(currentUser.uid)) selectedMemberIds.add(currentUser.uid);

    List<DateTime> dates = [];
    if (recurrenceType == 'None') {
      dates.add(selectedStartTime);
    } else if (repeatUntil != null) {
      DateTime cur = selectedStartTime;
      while (!cur.isAfter(repeatUntil!)) {
        if (recurrenceType == 'Daily' ||
            (recurrenceType == 'Weekly' && selectedWeekDays.contains(cur.weekday)) ||
            recurrenceType == 'Monthly') {
          dates.add(cur);
        }
        cur = recurrenceType == 'Monthly'
            ? DateTime(cur.year, cur.month + 1, cur.day)
            : cur.add(Duration(days: recurrenceType == 'Weekly' ? 1 : 1));
      }
    }

    for (final startDate in dates) {
      final endDate = startDate.add(selectedEndTime.difference(selectedStartTime));
      final overlapSnap = await firestore
          .collection('Meetings')
          .where('room_id', isEqualTo: widget.roomId)
          .get();

      final conflict = overlapSnap.docs.any((doc) {
        final data = doc.data();
        final mStart = (data['start_time'] as Timestamp).toDate();
        final mEnd = (data['end_time'] as Timestamp).toDate();
        return startDate.isBefore(mEnd) && endDate.isAfter(mStart);
      });
      if (conflict) return showMessage("Time conflict! Try another time.");

      await firestore.collection('Meetings').add({
        'room_id': widget.roomId,
        'start_time': Timestamp.fromDate(startDate),
        'end_time': Timestamp.fromDate(endDate),
        'title': meetingTitle,
        'users': selectedMemberIds,
        'notes': notesController.text.trim(),
      });

      for (final userId in selectedMemberIds) {
        try {
          final msg = userId == currentUser.uid
              ? 'You created "$meetingTitle" at ${DateFormat('yyyy-MM-dd HH:mm').format(startDate)}'
              : 'You have been invited to "$meetingTitle"';
          await firestore.collection('notifications').add({
            'userId': userId,
            'title': meetingTitle,
            'body': msg,
            'senderName': currentUser.email ?? 'Unknown',
            'timestamp': Timestamp.now(),
            'isRead': false,
          });
        } catch (_) {}
      }
    }

    setState(() {
      bookingSummary =
      'Room: $roomName\nDate: ${DateFormat('yyyy-MM-dd HH:mm').format(selectedStartTime)}\nTitle: $meetingTitle\nMembers: ${selectedMemberIds.length}\nNotes: ${notesController.text.trim()}';
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: const Text("Meeting(s) booked successfully!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void showMessage(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  Widget buildEquipmentChips() {
    if (equipment == null || equipment!.isEmpty) {
      return const Text("No equipment available",
          style: TextStyle(fontStyle: FontStyle.italic));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: equipment!.map((eq) {
        return Chip(
          label: Text(eq),
          backgroundColor: Colors.blue.shade50,
          labelStyle: TextStyle(
              color: Colors.blue.shade900, fontWeight: FontWeight.w600),
          avatar: const Icon(Icons.settings, size: 18, color: Colors.blueAccent),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Meeting"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
        future: getTeamMembers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final team = snapshot.data!;
          final filtered = team.where((member) {
            final name = '${member['first_name']} ${member['last_name']}'.toLowerCase();
            final email = member['email'].toLowerCase();
            final q = memberSearch.toLowerCase();
            return name.contains(q) || email.contains(q);
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.blue.shade100, blurRadius: 16)],
              ),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 12),

                  // --- Room Info ---
                  Text(roomName ?? 'Loading...', style: theme.textTheme.titleLarge!.copyWith(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.group, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text('Capacity: ${capacity ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 20),
                      Icon(Icons.location_on, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Flexible(child: Text(location ?? '-', overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Equipment:', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  buildEquipmentChips(),
                  const Divider(height: 32, thickness: 1, color: Colors.blueGrey),

                  // --- Start/End Time Cards ---
                  // --- Meeting Title Field ---
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Meeting Title',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.schedule, color: Colors.blue),
                      title: Text('Start Time', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(DateFormat('EEE, MMM d, yyyy • HH:mm').format(selectedStartTime)),
                      trailing: const Icon(Icons.lock, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.schedule, color: Colors.blue),
                      title: Text('End Time', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(DateFormat('EEE, MMM d, yyyy • HH:mm').format(selectedEndTime)),
                      trailing: const Icon(Icons.access_time, color: Colors.blue),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedEndTime),
                        );
                        if (time != null) {
                          setState(() {
                            selectedEndTime = DateTime(
                              selectedEndTime.year,
                              selectedEndTime.month,
                              selectedEndTime.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 15),

                  // --- Recurrence Dropdown ---
                  DropdownButtonFormField<String>(
                    value: recurrenceType,
                    decoration: const InputDecoration(
                      labelText: "Recurrence",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.repeat, color: Colors.blue),
                    ),
                    items: recurrenceOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) {
                      setState(() {
                        recurrenceType = val!;
                        if (recurrenceType != 'Weekly') selectedWeekDays.clear();
                      });
                    },
                  ),

                  if (recurrenceType == 'Weekly')
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        children: weekDayLabels.entries.map((e) {
                          return FilterChip(
                            label: Text(e.value),
                            selected: selectedWeekDays.contains(e.key),
                            onSelected: (val) {
                              setState(() {
                                val ? selectedWeekDays.add(e.key) : selectedWeekDays.remove(e.key);
                              });
                            },
                            backgroundColor: Colors.blue.shade50,
                            selectedColor: Colors.blue.shade300,
                            labelStyle: TextStyle(color: Colors.blue.shade900),
                          );
                        }).toList(),
                      ),
                    ),

                  if (recurrenceType != 'None')
                    ListTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.blue),
                      title: Text(repeatUntil == null
                          ? 'Repeat Until...'
                          : 'Repeat Until: ${DateFormat('yyyy-MM-dd').format(repeatUntil!)}'),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedStartTime,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) setState(() => repeatUntil = date);
                      },
                    ),


                  // --- Members Selection ---
                  ExpansionTile(
                    title: Text(
                      "Select Members (${selectedMemberIds.length})",
                      style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                    ),
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Search Members',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) => setState(() => memberSearch = val),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 250,
                        child: filtered.isEmpty
                            ? const Center(child: Text("No members found"))
                            : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final member = filtered[i];
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
                          },
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32, thickness: 1, color: Colors.blueGrey),


                  // --- Notes Field ---
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Optional Notes',
                      prefixIcon: const Icon(Icons.note),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Book Button ---
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                      shadowColor: Colors.blue.shade200,
                    ),
                    onPressed: saveMeeting,
                    child: const Text("Book Meeting", style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
