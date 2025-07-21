import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../LogIn/logIn_Screen.dart';
import '../workspace/create_Workspace_Screen.dart';
import 'Preference/Preference_Screen.dart';

Widget drawerSection(BuildContext context) {
  return Drawer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DrawerHeader(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Workspaces",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: AssetImage('Images/harriLogo.png'),
                  ),
                  SizedBox(width: 120),
                  TextButton(
                    onPressed: () {},
                    child: Text("Edit",
                        style: TextStyle(color: Colors.blue, fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.add),
                  title: Text("Add a workspace"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateWorkspace()),
                    );
                  },
                ),
                ListTile(
                    leading: Icon(Icons.settings),
                    title: Text("Preference"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PreferenceScreen()),
                      );
                    }),
                ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text("Help"),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.logout, color: Colors.red),
          title: Text("Sign Out", style: TextStyle(color: Colors.red)),
          onTap: () async {
            bool confirmSignOut = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Sign Out"),
                    content: Text("Are you sure you want to sign out?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text("Sign Out",
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ) ??
                false;
            if (confirmSignOut) {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              }
            }
          },
        ),
        SizedBox(height: 70),
      ],
    ),
  );
}
