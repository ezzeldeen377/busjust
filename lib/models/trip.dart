import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String driverId;
  final String busId;
  final GeoPoint startPoint;
  final GeoPoint endPoint;
  final String status;
  final DateTime? createdAt;

  Trip({
    required this.id,
    required this.driverId,
    required this.busId,
    required this.startPoint,
    required this.endPoint,
    required this.status,
    this.createdAt,
  });

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as String,
      driverId: map['driverId'] as String,
      busId: map['busId'] as String,
      startPoint: map['startPoint'] as GeoPoint,
      endPoint: map['endPoint'] as GeoPoint,
      status: map['status'] as String,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'busId': busId,
      'startPoint': startPoint,
      'endPoint': endPoint,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}