import 'package:bus_just/models/trip.dart';
import 'package:bus_just/models/user.dart';
import 'package:bus_just/models/student.dart';
import 'package:bus_just/screen/auth/control_screen.dart';
import 'package:bus_just/screen/auth/login_screen.dart';
import 'package:bus_just/screen/auth/signup_screen.dart';
import 'package:bus_just/screen/home/home_screen.dart';
import 'package:bus_just/screen/home/student_home_screen.dart';
import 'package:bus_just/screen/home/trip_history_screen.dart';
import 'package:bus_just/screen/map/map_screen.dart';
import 'package:bus_just/screen/map/enhanced_map_screen.dart';
import 'package:bus_just/screen/splash_screen.dart';
import 'package:bus_just/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case Routes.control:
        return MaterialPageRoute(builder: (_) => const ControlScreen());
      
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case Routes.signup:
        final type = settings.arguments as UserRole;
        return MaterialPageRoute(builder: (_) => SignUpScreen(userType:type));
      case Routes.home:
        final userData = settings.arguments as UserModel;
        return MaterialPageRoute(builder: (_) => HomeScreen(user: userData));
      
      case Routes.map:
        final args = settings.arguments;
        if (args != null && args is Map<String, dynamic>) {
          final busLocation = args['busLocation'] as LatLng?;
          final tripId = args['tripId'] as String?;
          final stations=args['stations'] as List<Station>;
          return MaterialPageRoute(
            builder: (_) => EnhancedMapScreen(
              initialBusLocation: busLocation,
              busId: tripId!,
              stations: stations,
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const MapScreen());
        
      case Routes.tripHistory:
        final userData = settings.arguments as UserModel;
        return MaterialPageRoute(builder: (_) => TripHistoryScreen(user: userData));
      
      default:

        
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}