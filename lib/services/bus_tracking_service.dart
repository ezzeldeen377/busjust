import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_just/models/trip.dart';
import 'package:bus_just/models/bus_stop.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusTrackingService {
  static final BusTrackingService instance = BusTrackingService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory BusTrackingService() {
    return instance;
  }

  BusTrackingService._internal();

  // Get active trips for a specific route
  Stream<List<Trip>> getActiveTripsForRoute(String routeId) {
    return _firestore
        .collection('trips')
        .where('routeId', isEqualTo: routeId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Trip.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
        });
  }

  // Get real-time bus location for a specific trip
  Stream<LatLng> getBusLocationStream(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            throw Exception('Trip not found');
          }
          
          final data = snapshot.data() as Map<String, dynamic>;
          final GeoPoint location = data['currentLocation'] as GeoPoint;
          return LatLng(location.latitude, location.longitude);
        });
  }

  // Get bus stops for a specific trip
  Future<List<BusStop>> getBusStopsForTrip(String tripId) async {
    try {
      final querySnapshot = await _firestore
          .collection('busStops')
          .where('tripId', isEqualTo: tripId)
          .orderBy('sequence')
          .get();
      
      return querySnapshot.docs
          .map((doc) => BusStop.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get bus stops: ${e.toString()}');
    }
  }

  // Calculate estimated arrival time based on current location and speed
  Future<DateTime?> getEstimatedArrivalTime(String tripId, String stopId) async {
    try {
      // This is a simplified calculation. In a real app, you would use
      // distance and average speed to calculate a more accurate ETA
      final tripDoc = await _firestore.collection('trips').doc(tripId).get();
      final stopDoc = await _firestore.collection('busStops').doc(stopId).get();
      
      if (!tripDoc.exists || !stopDoc.exists) {
        return null;
      }
      
      final tripData = tripDoc.data() as Map<String, dynamic>;
      final stopData = stopDoc.data() as Map<String, dynamic>;
      
      // Get current location and stop location
      final GeoPoint currentLocation = tripData['currentLocation'] as GeoPoint;
      final GeoPoint stopLocation = stopData['location'] as GeoPoint;
      
      // Calculate distance (simplified)
      final double lat1 = currentLocation.latitude;
      final double lon1 = currentLocation.longitude;
      final double lat2 = stopLocation.latitude;
      final double lon2 = stopLocation.longitude;
      
      // Simplified distance calculation using Euclidean distance
      // In a real app, you would use the Haversine formula or a mapping service API
      final double distance = _calculateDistance(lat1, lon1, lat2, lon2);
      
      // Assume average speed of 30 km/h
      final double averageSpeed = 30.0; // km/h
      
      // Calculate time in hours
      final double timeInHours = distance / averageSpeed;
      
      // Convert to minutes
      final int timeInMinutes = (timeInHours * 60).round();
      
      // Calculate estimated arrival time
      final DateTime now = DateTime.now();
      final DateTime estimatedArrival = now.add(Duration(minutes: timeInMinutes));
      
      return estimatedArrival;
    } catch (e) {
      throw Exception('Failed to calculate ETA: ${e.toString()}');
    }
  }
  
  // Simple distance calculation (Euclidean distance)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Convert to radians
    final double phi1 = lat1 * (3.14159265359 / 180);
    final double phi2 = lat2 * (3.14159265359 / 180);
    final double lambda1 = lon1 * (3.14159265359 / 180);
    final double lambda2 = lon2 * (3.14159265359 / 180);
    
    // Earth radius in kilometers
    const double earthRadius = 6371.0;
    
    // Haversine formula
    final double dLat = phi2 - phi1;
    final double dLon = lambda2 - lambda1;
    final double a = _sqr(Math.sin(dLat / 2)) + 
                     Math.cos(phi1) * Math.cos(phi2) * _sqr(Math.sin(dLon / 2));
    final double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    final double distance = earthRadius * c;
    
    return distance;
  }
  
  // Square function
  double _sqr(double x) {
    return x * x;
  }
}

// Math utility class
class Math {
  static double sin(double x) {
    return Math.sin(x);
  }
  
  static double cos(double x) {
    return Math.cos(x);
  }
  
  static double sqrt(double x) {
    return Math.sqrt(x);
  }
  
  static double atan2(double y, double x) {
    return Math.atan2(y, x);
  }
}