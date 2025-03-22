import 'package:cloud_firestore/cloud_firestore.dart';

class Shift {
  final String id;
  final String driverId;
  final DateTime startTime;
  final DateTime? endTime;
  final String status; // 'active', 'completed', 'cancelled'
  final int? duration; // in minutes

  Shift({
    required this.id,
    required this.driverId,
    required this.startTime,
    this.endTime,
    required this.status,
    this.duration,
  });

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'] as String,
      driverId: map['driverId'] as String,
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp?)?.toDate(),
      status: map['status'] as String,
      duration: map['duration'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'status': status,
      'duration': duration,
    };
  }
}