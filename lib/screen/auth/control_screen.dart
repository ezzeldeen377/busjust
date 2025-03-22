import 'package:bus_just/models/user.dart';
import 'package:bus_just/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ControlScreen extends StatelessWidget {

  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpeg'), // ضع هنا مسار الصورة
            fit: BoxFit.fill,  // لجعل الصورة تغطي الخلفية بالكامل
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // المربع الأول في الأعلى
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40), // مسافة من الأعلى
              child: _buildLoginBox(
                icon: FontAwesomeIcons.userGraduate,
                label: "Student",
                onTap: () {
                  Navigator.pushNamed(context, Routes.signup,arguments:UserRole.student );
                },
              ),
            ),
            // صف المربعات الأخرى تحت الأول
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLoginBox(
                    icon: FontAwesomeIcons.userShield,
                    label: "Admin",
                    onTap: () {
                      Navigator.pushNamed(context,  Routes.signup,arguments:UserRole.admin);
                    },
                  ),
                  const SizedBox(width: 20), // مسافة بين المربعات
                  _buildLoginBox(
                    icon: FontAwesomeIcons.bus,
                    label: "Driver",
                    onTap: () {
                      Navigator.pushNamed(context,  Routes.signup,arguments:UserRole.driver);
                    },
                  ),
                ],
              ),
              
            ),
           const SizedBox(height: 20), // مسافة بين المربعات

          ],
        ),
      ),
    );
  }

  Widget _buildLoginBox({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85), // شفافية على اللون الأبيض
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              spreadRadius: 2,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 45, color: const Color(0xFF0072ff)),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
