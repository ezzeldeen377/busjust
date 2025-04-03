import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_just/models/feedback.dart' as bus_feedback;
import 'package:bus_just/models/lost_item.dart';

class StudentService {
  static final StudentService instance = StudentService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory StudentService() {
    return instance;
  }

  StudentService._internal();

  // Submit feedback
  Future<void> submitFeedback(bus_feedback.Feedback feedback) async {
    try {
      await _firestore.collection('feedback').doc(feedback.id).set(feedback.toMap());
    } catch (e) {
      throw Exception('Failed to submit feedback: ${e.toString()}');
    }
  }

  // Get feedback history for a student
  Future<List<bus_feedback.Feedback>> getFeedbackHistory(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('feedback')
          .where('studentId', isEqualTo: studentId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => bus_feedback.Feedback.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get feedback history: ${e.toString()}');
    }
  }

  // Report lost item
  Future<void> reportLostItem(LostItem lostItem) async {
    try {
      await _firestore.collection('lostItems').doc(lostItem.id).set(lostItem.toMap());
    } catch (e) {
      throw Exception('Failed to report lost item: ${e.toString()}');
    }
  }

  // Get lost item reports for a student
  Future<List<LostItem>> getLostItemReports(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('lostItems')
          .where('studentId', isEqualTo: studentId)
          .orderBy('reportDate', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => LostItem.fromMap(doc.data() as Map<String, dynamic>))  
          .toList();
    } catch (e) {
      throw Exception('Failed to get lost item reports: ${e.toString()}');
    }
  }

  // Get all lost items (for admin or driver view)
  Future<List<LostItem>> getAllLostItems() async {
    try {
      final querySnapshot = await _firestore
          .collection('lostItems')
          .orderBy('reportDate', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => LostItem.fromMap(doc.data() as Map<String, dynamic>))  
          .toList();
    } catch (e) {
      throw Exception('Failed to get all lost items: ${e.toString()}');
    }
  }

  // Update lost item status
  Future<void> updateLostItemStatus(String itemId, String newStatus) async {
    try {
      await _firestore.collection('lostItems').doc(itemId).update({
        'status': newStatus
      });
    } catch (e) {
      throw Exception('Failed to update lost item status: ${e.toString()}');
    }
  }

  // Get real-time bus location updates
  Stream<DocumentSnapshot> getBusLocationUpdates(String busId) {
    try {
      return _firestore.collection('buses').doc(busId).snapshots();
    } catch (e) {
      throw Exception('Failed to get bus location updates: ${e.toString()}');
    }
  }

  // Get estimated arrival time for a specific bus
  Future<DateTime?> getEstimatedArrivalTime(String busId, String stopId) async {
    try {
      final doc = await _firestore
          .collection('busSchedules')
          .where('busId', isEqualTo: busId)
          .where('stopId', isEqualTo: stopId)
          .get();
      
      if (doc.docs.isEmpty) return null;
      
      final data = doc.docs.first.data();
      return (data['estimatedArrival'] as Timestamp).toDate();
    } catch (e) {
      throw Exception('Failed to get estimated arrival time: ${e.toString()}');
    }
  }

  // Get available routes for a student
  Future<List<Map<String, dynamic>>> getAvailabletTrips() async {
    try {
      final querySnapshot = await _firestore
          .collection('trips')
          .where('status', isEqualTo: "active")
          .get();
      
      return querySnapshot.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      throw Exception('Failed to get available routes: ${e.toString()}');
    }
  }

  // Select a route for a student
  Future<void> selectRoute(String studentId, String routeId) async {
    try {
      await _firestore.collection('users').doc(studentId).update({
        'selectedRouteId': routeId,
        'lastUpdated': Timestamp.now()
      });
    } catch (e) {
      throw Exception('Failed to select route: ${e.toString()}');
    }
  }

  // Subscribe to notifications
  Future<void> subscribeToNotifications(String studentId, List<String> topics) async {
    try {
      await _firestore.collection('notifications').doc(studentId).set({
        'topics': topics,
        'lastUpdated': Timestamp.now()
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to subscribe to notifications: ${e.toString()}');
    }
  }
}