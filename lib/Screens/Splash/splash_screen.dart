import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:graduation_project/Screens/Welcome/Welcome_Screen.dart';
import '../DashBoard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()));
    });
  }

  void checkLoginStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(child: Image.asset('Images/logo.png')),
    );
  }
}
