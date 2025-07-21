import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('team').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          print("Document for user ${user.uid} does not exist in Firestore.");
          return Scaffold(
            body: Center(child: Text('No data found for the user')),
          );
        }
        var userData = snapshot.data!.data() as Map<String, dynamic>;
        userData['first_name'] = userData['first_name'] ?? 'No Name';
        userData['last_name'] = userData['last_name'] ?? 'No Name';
        userData['email'] = user.email;
        userData['phone'] = userData['phone'] ?? 'Not Provided';
        userData['location'] = userData['location'] ?? 'Unknown';
        userData['joinedDate'] = user.metadata.creationTime?.toLocal().toString().split(' ')[0] ?? 'N/A';
        userData['profilePic'] = user.photoURL;
        return Scaffold(
          body: ProfileBody(userData: userData),
        );
      },
    );
  }
}

class ProfileBody extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfileBody({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Center(
              child: ClipOval(
                  child: CircleAvatar(
                    radius: 60,
                    child: Icon(Icons.person, size: 60, color: Colors.blueAccent),
                  ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userData['first_name'] ?? 'No Name',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  userData['last_name'] ?? 'No Name',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              userData['email'] ?? 'No Email',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 30),
            buildInfoCard(Icons.phone, "Phone", userData['phone'] ?? 'Not Provided'),
            buildInfoCard(Icons.location_on, "Location", userData['location'] ?? 'Unknown'),
            buildInfoCard(Icons.calendar_today, "Joined Date", userData['joinedDate'] ?? 'N/A'),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget buildInfoCard(IconData icon, String title, String value) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          value,
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
      ),
    );
  }}
