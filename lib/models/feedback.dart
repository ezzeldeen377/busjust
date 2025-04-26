import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final bool isResolved;
  final String message;
  final int rating;
  final String routeId;
  final String studentId;
  final String studentName;
  final DateTime timestamp;
  final String tripId;
  final String? routeName;
  final String? tripName;

  FeedbackModel({
    required this.id,
    required this.isResolved,
    required this.message,
    required this.rating,
    required this.routeId,
    required this.studentId,
    required this.studentName,
    required this.timestamp,
    required this.tripId,
    this.routeName,
    this.tripName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isResolved': isResolved,
      'message': message,
      'rating': rating,
      'routeId': routeId,
      'studentId': studentId,
      'studentName': studentName,
      'timestamp': Timestamp.fromDate(timestamp),
      'tripId': tripId,
      'routeName': routeName,
      'tripName': tripName,
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      id: map['id'] ?? '',
      isResolved: map['isResolved'] ?? false,
      message: map['message'] ?? '',
      rating: map['rating']?.toInt() ?? 0,
      routeId: map['routeId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      timestamp: map['timestamp'] is Timestamp 
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      tripId: map['tripId'] ?? '',
      routeName: map['routeName'],
      tripName: map['tripName'],
    );
  }
}

