import 'package:cloud_firestore/cloud_firestore.dart';

class RouteUpdate {
  final String id;
  final String driverId;
  final String? tripId;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  RouteUpdate({
    required this.id,
    required this.driverId,
    this.tripId,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  factory RouteUpdate.fromMap(Map<String, dynamic> map) {
    return RouteUpdate(
      id: map['id'] as String,
      driverId: map['driverId'] as String,
      tripId: map['tripId'] as String?,
      message: map['message'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'tripId': tripId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}