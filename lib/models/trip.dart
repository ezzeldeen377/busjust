// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Trip {
  final String?id;
  final String? driverId;
  final String? busId;
  final List<Station>? stations;
  final String? status;
  final DateTime? createdAt;
  final DateTime? lastUpdate;  // Added
  final List<String>? studentIds;  // Added
  final double? distance;
  final int? estimatedTimeMinutes;

  Trip({
     this.id,
     this.driverId,
     this.busId,
     this.stations,
     this.status,
     this.createdAt,
     this.lastUpdate,  // Added
     this.studentIds,  // Added
     this.distance,
     this.estimatedTimeMinutes,
  });

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as String,
      driverId: map['driverId'] as String,
      busId: map['busId'] as String,
      stations: map['stations'] != null 
          ? List<Station>.from((map['stations'] as List).map((x) => Station.fromMap(x as Map<String, dynamic>)))
          : null,
      status: map['status'] as String,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      lastUpdate: map['lastUpdate'] != null ? (map['lastUpdate'] as Timestamp).toDate() : null,  // Added
      studentIds: map['studentIds'] != null ? List<String>.from(map['studentIds']) : null,  // Added
      distance: map['distance'] != null ? (map['distance'] as num).toDouble() : null,
      estimatedTimeMinutes: map['estimatedTimeMinutes'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'driverId': driverId,
      'busId': busId,
      'stations': stations?.map((x) => x.toMap()).toList(),
      'status': status,
      'createdAt': createdAt,
      'lastUpdate': lastUpdate,  // Added
      'studentIds': studentIds,  // Added
      'distance': distance,
      'estimatedTimeMinutes': estimatedTimeMinutes,
    };
  }

  Trip copyWith({
    String? id,
    String? driverId,
    String? busId,
    List<Station>? stations,
    String? status,
    DateTime? createdAt,
    DateTime? lastUpdate,  // Added
    List<String>? studentIds,  // Added
    bool? isActive,
    double? distance,
    int? estimatedTimeMinutes,
  }) {
    return Trip(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      busId: busId ?? this.busId,
      stations: stations ?? this.stations,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastUpdate: lastUpdate ?? this.lastUpdate,  // Added
      studentIds: studentIds ?? this.studentIds,  // Added
      distance: distance ?? this.distance,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
    );
  }

  String toJson() => json.encode(toMap());

  factory Trip.fromJson(String source) => Trip.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Trip(id: $id, driverId: $driverId, busId: $busId, stations: $stations, status: $status, createdAt: $createdAt, lastUpdate: $lastUpdate, studentIds: $studentIds, distance: $distance, estimatedTimeMinutes: $estimatedTimeMinutes)';  // Updated
  }

  @override
  bool operator ==(covariant Trip other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.driverId == driverId &&
      other.busId == busId &&
      listEquals(other.stations, stations) &&
      other.status == status &&
      other.createdAt == createdAt &&
      other.lastUpdate == lastUpdate &&  // Added
      listEquals(other.studentIds, studentIds) &&  // Added
      other.distance == distance &&
      other.estimatedTimeMinutes == estimatedTimeMinutes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      driverId.hashCode ^
      busId.hashCode ^
      stations.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      lastUpdate.hashCode ^  // Added
      studentIds.hashCode ^  // Added
      distance.hashCode ^
      estimatedTimeMinutes.hashCode;
  }
}
extension LatLngExtension on LatLng {
  GeoPoint toGeoPoint() {
    return GeoPoint(latitude, longitude);
  }
}

class Station {
  final String? name;
  final GeoPoint? point;

  Station({
    this.name,
    this.point,
  });

  factory Station.fromMap(Map<String, dynamic> map) {
    GeoPoint? geoPoint;
    if (map['point'] is GeoPoint) {
      geoPoint = map['point'] as GeoPoint;
    } else if (map['point'] is Map<String, dynamic>) {
      final pointMap = map['point'] as Map<String, dynamic>;
      geoPoint = GeoPoint(
        (pointMap['latitude'] as num).toDouble(),
        (pointMap['longitude'] as num).toDouble(),
      );
    }
    return Station(
      name: map['name'] as String?,
      point: geoPoint,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'point': point,
    };
  }

  @override
  String toString() => 'Station(name: $name, point: $point)';

  
}