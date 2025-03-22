import 'package:bus_just/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue[50]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.directions_bus, color: Color(0xFF0072ff)),
                title: const Text('Next Bus Arrival'),
                subtitle: const Text('10 minutes'),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.map);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0072ff),
                  ),
                  child: const Text('Track'),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome to Bus Just',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0072ff),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement book ride functionality
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0072ff),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Book a Ride'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}