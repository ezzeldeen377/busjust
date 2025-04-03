// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Bus {
  final String? id;
  final String? busNumber;
  final int? capacity;
  final String? driverId;
  final String? routeId;
  final GeoPoint? currentLocation;
  final bool? isActive;
  final String? busName;

  Bus({
    this.id,
    this.busNumber,
    this.capacity,
    this.driverId,
    this.routeId,
    this.currentLocation,
    this.isActive = false,
    this.busName,
  });

  // Create a Bus from a Map (for Firestore)
  factory Bus.fromMap(Map<String, dynamic> map) {
    return Bus(
      id: map['id'] != null ? map['id'] as String : null,
      busNumber: map['busNumber'] != null ? map['busNumber'] as String : null,
      capacity: map['capacity'] != null ? map['capacity'] as int : null,
      driverId: map['driverId'] != null ? map['driverId'] as String : null,
      routeId: map['routeId'] != null ? map['routeId'] as String : null,
      currentLocation: switch (map['currentLocation']) {
        GeoPoint gp => gp,
        Map<String, dynamic> loc => GeoPoint(
            (loc['latitude'] ?? 0).toDouble(),
            (loc['longitude'] ?? 0).toDouble(),
          ),
        _ => null, // Return null if it's missing or invalid
      },
      isActive: map['isActive'] != null ? map['isActive'] as bool : null,
      busName: map['busName'] != null ? map['busName'] as String : null,
    );
  }

  // Convert Bus to a Map (for Firestore)
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'busNumber': busNumber,
      'capacity': capacity,
      'driverId': driverId,
      'routeId': routeId,
      'currentLocation': currentLocation,
      'isActive': isActive,
      'busName': busName,
    };
  }

  // Create a copy of this Bus with the given fields updated
  Bus copyWith({
    String? id,
    String? busNumber,
    int? capacity,
    String? driverId,
    String? routeId,
    GeoPoint? currentLocation,
    bool? isActive,
    String? busName,
  }) {
    return Bus(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      capacity: capacity ?? this.capacity,
      driverId: driverId ?? this.driverId,
      routeId: routeId ?? this.routeId,
      currentLocation: currentLocation ?? this.currentLocation,
      isActive: isActive ?? this.isActive,
      busName: busName ?? this.busName,
    );
  }

  String toJson() => json.encode(toMap());

  factory Bus.fromJson(String source) =>
      Bus.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Bus(id: $id, busNumber: $busNumber, capacity: $capacity, driverId: $driverId, routeId: $routeId, currentLocation: $currentLocation, isActive: $isActive, busName: $busName)';
  }

  @override
  bool operator ==(covariant Bus other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.busNumber == busNumber &&
        other.capacity == capacity &&
        other.driverId == driverId &&
        other.routeId == routeId &&
        other.currentLocation == currentLocation &&
        other.isActive == isActive &&
        other.busName == busName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        busNumber.hashCode ^
        capacity.hashCode ^
        driverId.hashCode ^
        routeId.hashCode ^
        currentLocation.hashCode ^
        isActive.hashCode ^
        busName.hashCode;
  }
}
