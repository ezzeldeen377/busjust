import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_just/models/route_update.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory NotificationService() {
    return instance;
  }

  NotificationService._internal();

  // Stream of route updates for a specific student's preferred route
  Stream<List<RouteUpdate>> getRouteUpdatesStream(String preferredBusRoute) {
    return _firestore
        .collection('routeUpdates')
        .where('routeId', isEqualTo: preferredBusRoute)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RouteUpdate.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
        });
  }

  // Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('routeUpdates').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: ${e.toString()}');
    }
  }

  // Show a local notification
  void showLocalNotification(BuildContext context, String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF0072ff),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}