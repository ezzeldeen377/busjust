import 'package:cloud_firestore/cloud_firestore.dart';

class BusStop {
  final String id;
  final String name;
  final String tripId;
  final int sequence;
  final int studentCount;
  final GeoPoint location;
  final DateTime? arrivalTime;
  final DateTime? departureTime;

  BusStop({
    required this.id,
    required this.name,
    required this.tripId,
    required this.sequence,
    required this.studentCount,
    required this.location,
    this.arrivalTime,
    this.departureTime,
  });

  factory BusStop.fromMap(Map<String, dynamic> map) {
    return BusStop(
      id: map['id'] as String,
      name: map['name'] as String,
      tripId: map['tripId'] as String,
      sequence: map['sequence'] as int,
      studentCount: map['studentCount'] as int,
      location: map['location'] as GeoPoint,
      arrivalTime: (map['arrivalTime'] as Timestamp?)?.toDate(),
      departureTime: (map['departureTime'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tripId': tripId,
      'sequence': sequence,
      'studentCount': studentCount,
      'location': location,
      'arrivalTime': arrivalTime != null ? Timestamp.fromDate(arrivalTime!) : null,
      'departureTime': departureTime != null ? Timestamp.fromDate(departureTime!) : null,
    };
  }
}