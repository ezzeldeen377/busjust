import 'package:bus_just/models/bus.dart';
import 'package:bus_just/models/driver.dart';
import 'package:bus_just/models/trip.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_just/models/feedback.dart' as bus_feedback;
import 'package:bus_just/models/lost_item.dart';

class StudentService {
  static final StudentService instance = StudentService._internal();

  factory StudentService() {
    return instance;
  }

  StudentService._internal();

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

  static CollectionReference<Map<String, dynamic>>
      get busMalfunctionsCollection =>
          FirebaseFirestore.instance.collection('bus_malfunctions');
  // Submit feedback
  static Future<void> submitFeedback(
      bus_feedback.FeedbackModel feedback) async {
    try {
      await feedbackCollection.doc(feedback.id).set(feedback.toMap());
    } catch (e) {
      throw Exception('Failed to submit feedback: ${e.toString()}');
    }
  }

  // Get feedback history for a student
  static Future<List<bus_feedback.FeedbackModel>> getFeedbackHistory(
      String studentId) async {
    try {
      final querySnapshot = await feedbackCollection
          .where('studentId', isEqualTo: studentId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => bus_feedback.FeedbackModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get feedback history: ${e.toString()}');
    }
  }

  // Report lost item
  static Future<void> reportLostItem(LostItem lostItem) async {
    try {
      await lostItemsCollection.doc(lostItem.id).set(lostItem.toMap());
    } catch (e) {
      throw Exception('Failed to report lost item: ${e.toString()}');
    }
  }

  // Get lost item reports for a student
  static Future<List<LostItem>> getLostItemReports(String studentId) async {
    try {
      final querySnapshot = await lostItemsCollection
          .where('studentId', isEqualTo: studentId)
          .orderBy('reportDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => LostItem.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get lost item reports: ${e.toString()}');
    }
  }

  // Get all lost items (for admin or driver view)
  static Future<List<LostItem>> getAllLostItems() async {
    try {
      final querySnapshot = await lostItemsCollection
          .orderBy('reportDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => LostItem.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all lost items: ${e.toString()}');
    }
  }

  // Update lost item status
  static Future<void> updateLostItemStatus(
      String itemId, String newStatus) async {
    try {
      await lostItemsCollection.doc(itemId).update({'status': newStatus});
    } catch (e) {
      throw Exception('Failed to update lost item status: ${e.toString()}');
    }
  }

  // Get real-time bus location updates
  static Stream<DocumentSnapshot> getBusLocationUpdates(String busId) {
    try {
      return busesCollection.doc(busId).snapshots();
    } catch (e) {
      throw Exception('Failed to get bus location updates: ${e.toString()}');
    }
  }
    static Future<DocumentSnapshot<Map<String, dynamic>>> getStudentData(String studentId) async {
    try {
      return await usersCollection.doc(studentId).get();
    } catch (e) {
      throw Exception('Failed to get student data: ${e.toString()}');
    }
  }
    static Future<DocumentSnapshot<Map<String, dynamic>>> getBusData(String busId) async {
    try {
      return await busesCollection.doc(busId).get();
    } catch (e) {
      throw Exception('Failed to get bus data: ${e.toString()}');
    }
  }
  // Get available routes for a student
  static Future<List<Map<String, dynamic>>> getAvailabletTrips() async {
    try {
      final querySnapshot =
          await tripsCollection.where('status', isEqualTo: "active").get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get available routes: ${e.toString()}');
    }
  }

  // Select a route for a student
  static Future<void> selectRoute(String studentId, String routeId) async {
    try {
      // Start a batch write
      final batch = FirebaseFirestore.instance.batch();

      // Update user's selected route
      batch.update(usersCollection.doc(studentId),
          {'selectedRouteId': routeId, 'lastUpdated': Timestamp.now()});

      // Add student to trip's passenger list
      batch.update(tripsCollection.doc(routeId), {
        'studentIds': FieldValue.arrayUnion([studentId]),
        'lastUpdated': Timestamp.now()
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to select route: ${e.toString()}');
    }
  }

  static Future<void> endTrip(String studentId) async {
    try {
      // Get current user data to find the route
      final userDoc = await usersCollection.doc(studentId).get();
      final currentRouteId = userDoc.data()?['selectedRouteId'];

      if (currentRouteId != null) {
        // Start a batch write
        final batch = FirebaseFirestore.instance.batch();

        // Remove selected route from user
        batch.update(usersCollection.doc(studentId),
            {'selectedRouteId': null, 'lastUpdated': Timestamp.now()});

        // Remove student from trip's passenger list

        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to end trip: ${e.toString()}');
    }
  }


  static Future<List<Trip>> getFinishedTrips(String studentId) async {
    try {
      final querySnapshot = await tripsCollection
          .where('studentIds', arrayContains: studentId)
          .where('status', isEqualTo: 'completed')
          .orderBy('startTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Trip.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching finished trips: $e');
      return [];
    }
  }
    static Future<Map<String, dynamic>> getTripDetails(String busId, String driverId) async {
    try {
      final results = await Future.wait([
        busesCollection.doc(busId).get(),
        usersCollection.doc(driverId).get(),
      ]);

      if (!results[0].exists || !results[1].exists) {
        throw Exception('Bus or driver data not found');
      }

      return {
        'bus': Bus.fromMap(results[0].data()!),
        'driver': Driver.fromMap(results[1].data()!),
      };
    } catch (e) {
      throw Exception('Failed to get trip details: ${e.toString()}');
    }
  }

  // Collection References
  static Future<List<Trip>> getStudentTripHistory(String studentId) async {
    try {
      final querySnapshot = await tripsCollection
          .where('studentIds', arrayContains: studentId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Trip.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get student trip history: ${e.toString()}');
    }
  }
}
