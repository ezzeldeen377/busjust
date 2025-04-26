import 'package:flutter/material.dart';
import 'package:bus_just/widgets/admin/active_trips_list.dart';
import 'package:bus_just/widgets/admin/bus_management.dart';
import 'package:bus_just/widgets/admin/drivers_list.dart';
import 'package:bus_just/widgets/admin/lost_reports.dart';
import 'package:bus_just/widgets/admin/feedback_reports.dart';
import 'package:bus_just/widgets/admin/bus_malfunction_reports.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF0072ff),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Reports & Management',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          
          ],
        ),
      ),
      body: Container(
        color: Colors.grey[100],
        child: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Trips',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              ActiveTripsList(),
              SizedBox(height: 24),
              BusManagement(),
              SizedBox(height: 24),
              DriversList(),
            ],
          ),
        ),
      ),
    );
  }
}