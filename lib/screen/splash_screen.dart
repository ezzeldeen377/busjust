import 'dart:async';

import 'package:bus_just/router/routes.dart';
import 'package:bus_just/services/auth_service.dart';
import 'package:bus_just/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {

  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 0),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuthState();
      }
    });
  }

  void _checkAuthState() {
    _authSubscription = AuthService.instance.authStateChanges.listen((User? user) async {
      if (!mounted) return;
      if (user != null) {
        final userData = await FirestoreService.instance.getUserData(user.uid);
        if (!mounted) return;
       Navigator.pushReplacementNamed(context, Routes.home,arguments: userData); 
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context ,Routes.login);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0072ff), Color(0xFF00c6ff)], // ألوان خلفية جذابة
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أنيميشن Lottie في المنتصف
            Lottie.asset(
              'assets/lottie/splash.json',
              width: 600,
              height: 600,
              fit: BoxFit.contain,
              controller: _controller,
              onLoaded: (composition) {
                _controller.duration = composition.duration;
                _controller.forward();
              },
            ),
            const Spacer(), // يضيف مسافة تلقائية بين اللوتي والنص
            // إصدار التطبيق في أسفل الشاشة
            const Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Text(
                "Version 1.0.0", // تغيير النص إلى الإنجليزية
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // جعل النص واضحًا على الخلفية
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
