import 'package:bus_just/router/router.dart';
import 'package:bus_just/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';

Future<void> _initializeApp() async {
  await Firebase.initializeApp();
  
  // Request location permission
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }
  
  if (permission == LocationPermission.deniedForever) {
    return Future.error('Location permissions are permanently denied');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await _initializeApp();
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Error initializing app: $e');
    runApp(const MyApp()); // Still run the app even if permissions are denied
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'University Bus System',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 18, 26, 181),
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(),
      ),
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: Routes.splash,
    );
  }

  const MyApp({super.key});
}
