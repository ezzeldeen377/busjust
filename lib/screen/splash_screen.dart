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
  StreamSubscription<User?>? _authSubscription;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuthState();
      }
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _checkAuthState() {
    _authSubscription = AuthService.instance.authStateChanges.listen((User? user) async {
      if (!mounted) return;
      if (user != null) {
        final userData = await FirestoreService.instance.getUserData(user.uid);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, Routes.home, arguments: userData);
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, Routes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0072ff), Color(0xFF00c6ff)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/lottie/splash.json',
              width: 600,
              height: 600,
              fit: BoxFit.contain,
              controller: _animationController,
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Text(
                "Version 1.0.0",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
