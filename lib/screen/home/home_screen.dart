import 'package:bus_just/models/user.dart';
import 'package:bus_just/models/student.dart';
import 'package:bus_just/router/routes.dart';
import 'package:bus_just/screen/admin/report_screen.dart';
import 'package:bus_just/screen/home/student_home_screen.dart';
import 'package:bus_just/screen/home/admin_home_screen.dart';
import 'package:bus_just/screen/home/driver_home_screen.dart';
import 'package:bus_just/screen/home/student_home_screen.dart';
import 'package:bus_just/widgets/admin/bus_malfunction_reports.dart';
import 'package:bus_just/widgets/admin/feedback_reports.dart';
import 'package:bus_just/widgets/admin/lost_reports.dart';
import 'package:flutter/material.dart';
import 'package:bus_just/services/auth_service.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Bus Just', style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: const Color(0xFF0072ff),
      ),
      drawer: Drawer(
        child: ListView(

          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0072ff), Color(0xFF00c6ff)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF0072ff),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.user.fullName ?? _authService.currentUser?.displayName ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.user.email ,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Map View'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.map);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Trip History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.tripHistory, arguments: widget.user);
              },
            ),
            if (widget.user.role == UserRole.admin) ...[
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Lost Items'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportScreen(
                        title: 'Lost Items Reports',
                        child: LostReports(),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.feedback),
                title: const Text('Feedback'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportScreen(
                        title: 'Feedback Reports',
                        child: FeedbackReports(),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.build),
                title: const Text('Bus Malfunctions'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportScreen(
                        title: 'Bus Malfunction Reports',
                        child: BusMalfunctionReports(),
                      ),
                    ),
                  );
                },
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
       body:_buildHomeContent()

    );
  }
Widget _buildHomeContent() {
print(widget.user.role);
if (widget.user.role ==UserRole.student ) {
  // Convert UserModel to Student model
  final student = Student(
    id: widget.user.id,
    fullName: widget.user.fullName ?? '',
    email: widget.user.email,
    phoneNumber: widget.user.phoneNumber,
    profilePicture: widget.user.profilePicture,
  );
  return StudentHomeScreen(student: student);

} else if (widget.user.role ==UserRole.driver) {

return DriverHomeScreen();

} else if (widget.user.role ==UserRole.admin) {

return AdminHomeScreen();

} else {

return const Center(child: Text("Unknown role"));

}

}
  void _handleLogout() async {
    try {
      await _authService.signOut();
      Navigator.pushReplacementNamed(context, Routes.login);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}