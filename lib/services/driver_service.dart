import 'package:bus_just/models/trip.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverService {
  static final DriverService instance = DriverService._internal();

  factory DriverService() {
    return instance;
  }

  DriverService._internal();

  static CollectionReference<Map<String, dynamic>> get usersCollection =>
      FirebaseFirestore.instance.collection('users');

  static CollectionReference<Map<String, dynamic>> get tripsCollection =>
      FirebaseFirestore.instance.collection('trips');

  static CollectionReference<Map<String, dynamic>> get lostItemsCollection =>
      FirebaseFirestore.instance.collection('lostItems');

  static CollectionReference<Map<String, dynamic>> get feedbackCollection =>
      FirebaseFirestore.instance.collection('feedback');

  static CollectionReference<Map<String, dynamic>> get busesCollection =>
      FirebaseFirestore.instance.collection('buses');

  static CollectionReference<Map<String, dynamic>> get busMalfunctionsCollection =>
      FirebaseFirestore.instance.collection('bus_malfunctions');

  static Future<List<Trip>> getDriverTrips(String driverId) async {
    try {
      final querySnapshot = await tripsCollection
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Trip.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get driver trips: ${e.toString()}');
    }
  }
}