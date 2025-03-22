import 'package:cloud_firestore/cloud_firestore.dart';

class LostItem {
  final String id;
  final String studentId;
  final String? tripId;
  final String? busId;
  final String itemName;
  final String description;
  final DateTime reportDate;
  final String status; // 'pending', 'found', 'claimed'
  final String? imageUrl;

  LostItem({
    required this.id,
    required this.studentId,
    this.tripId,
    this.busId,
    required this.itemName,
    required this.description,
    required this.reportDate,
    required this.status,
    this.imageUrl,
  });

  factory LostItem.fromMap(Map<String, dynamic> map) {
    return LostItem(
      id: map['id'] as String,
      studentId: map['studentId'] as String,
      tripId: map['tripId'] as String?,
      busId: map['busId'] as String?,
      itemName: map['itemName'] as String,
      description: map['description'] as String,
      reportDate: (map['reportDate'] as Timestamp).toDate(),
      status: map['status'] as String,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'tripId': tripId,
      'busId': busId,
      'itemName': itemName,
      'description': description,
      'reportDate': Timestamp.fromDate(reportDate),
      'status': status,
      'imageUrl': imageUrl,
    };
  }
}