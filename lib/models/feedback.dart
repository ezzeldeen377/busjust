import 'package:cloud_firestore/cloud_firestore.dart';

class Feedback {
  final String id;
  final String studentId;
  final String? tripId;
  final String? routeId;
  final String message;
  final int rating; // 1-5 star rating
  final DateTime timestamp;
  final bool isResolved;

  Feedback({
    required this.id,
    required this.studentId,
    this.tripId,
    this.routeId,
    required this.message,
    required this.rating,
    required this.timestamp,
    required this.isResolved,
  });

  factory Feedback.fromMap(Map<String, dynamic> map) {
    return Feedback(
      id: map['id'] as String,
      studentId: map['studentId'] as String,
      tripId: map['tripId'] as String?,
      routeId: map['routeId'] as String?,
      message: map['message'] as String,
      rating: map['rating'] as int,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isResolved: map['isResolved'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'tripId': tripId,
      'routeId': routeId,
      'message': message,
      'rating': rating,
      'timestamp': Timestamp.fromDate(timestamp),
      'isResolved': isResolved,
    };
  }
}