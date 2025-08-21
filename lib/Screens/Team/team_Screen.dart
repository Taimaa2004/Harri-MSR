import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation_project/Screens/Team/add_Member_Screen.dart';

class Teamscreen extends StatefulWidget {
  const Teamscreen({super.key});

  @override
  State<Teamscreen> createState() => _TeamscreenState();
}

class _TeamscreenState extends State<Teamscreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  String? userRole;
  String searchQuery = "";
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserRole();
  }

  Future<void> _fetchCurrentUserRole() async {
    String uid = auth.currentUser!.uid;
    DocumentSnapshot userDoc =
    await firestore.collection('team').doc(uid).get();

    if (userDoc.exists) {
      setState(() {
        userRole = userDoc.get('role') ?? 'member';
      });
    } else {
      setState(() {
        userRole = 'member';
      });
    }
  }

  Stream<List<Map<String, dynamic>>> _getTeamMembersStream() {
    String currentUserUid = auth.currentUser!.uid;
    return firestore.collection('team').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUserUid)
          .map((doc) {
        var data = doc.data();
        return {
          'firstName': data['first_name'] ?? 'No First Name',
          'lastName': data['last_name'] ?? 'No Last Name',
          'email': data['email'] ?? 'No Email',
          'role': data['role'] ?? 'No Role',
        };
      }).toList();
    });
  }

  void showProfileScreen(BuildContext context, Map<String, dynamic> member) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 12),
                Text(
                  "${member['firstName']} ${member['lastName']}",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ListTile(
                  leading: Icon(Icons.email, color: Colors.blue),
                  title: Text(member['email']),
                ),
                ListTile(
                  leading: Icon(Icons.work, color: Colors.blue),
                  title: Text("Role: ${member['role']}"),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text("Close"),
                ),
                SizedBox(height: 50)
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Team Members",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search team members...",
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: userRole == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getTeamMembersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No team members found.'));
          }

          // Filter members by search query
          var filteredMembers = snapshot.data!.where((member) {
            final fullName =
            "${member['firstName']} ${member['lastName']}".toLowerCase();
            final email = member['email'].toLowerCase();
            return fullName.contains(searchQuery) ||
                email.contains(searchQuery);
          }).toList();

          if (filteredMembers.isEmpty) {
            return Center(child: Text("No results found."));
          }

          return ListView.builder(
            itemCount: filteredMembers.length,
            itemBuilder: (context, index) {
              var member = filteredMembers[index];
              return Card(
                margin:
                EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.person, color: Colors.black87),
                  ),
                  title: Text(
                    '${member['firstName']} ${member['lastName']}',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(member['email']),
                  onTap: () => showProfileScreen(context, member),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: userRole == 'Admin'
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMember()),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.add, size: 30, color: Colors.white),
      )
          : null,
    );
  }
}
