import 'package:flutter/material.dart';
import 'package:graduation_project/ui/signUp_screen.dart';
import 'logIn_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(color: Colors.blue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center everything
          children: [
            Image.asset('Images/splash.png', width: 300, height: 320),
            const SizedBox(height: 60), // Spacing between image and text
            const Text(
              'Reserve your perfect meeting room in seconds!',
              textAlign: TextAlign.left,
              style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 200), // Spacing before buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center buttons
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(60),
                    ),
                    backgroundColor: Colors.white60,
                    foregroundColor: Colors.black,
                    elevation: 5,
                  ),
                  child: const Text('Log in', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 35), // Space between buttons
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignupScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(60),
                    ),
                    backgroundColor: Colors.white60,
                    foregroundColor: Colors.black,
                    elevation: 5,
                  ),
                  child: const Text('Sign up', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
