import 'package:cloud_firestore/cloud_firestore.dart';

class BusMalfunction {
  final String id;
  final String busId;
  final String issue;
  final String description;
  final String reporterName; // Added reporterName
  final String driverId;
  final String severity;
  final String status;
  final DateTime timestamp;
  final bool isFixed;

  BusMalfunction({
    required this.id,
    required this.busId,
    required this.issue,
    required this.description,
    required this.reporterName, // Added reporterName
    required this.driverId,
    required this.severity,
    required this.status,
    required this.timestamp,
    this.isFixed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'busId': busId,
      'issue': issue,
      'description': description,
      'reporterName': reporterName, // Added reporterName
      'driverId': driverId,
      'severity': severity,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'isFixed': isFixed,
    };
  }

  factory BusMalfunction.fromMap(Map<String, dynamic> map) {
    return BusMalfunction(
      id: map['id'] ?? '',
      busId: map['busId'] ?? '',
      issue: map['issue'] ?? '',
      description: map['description'] ?? '',
      reporterName: map['reporterName'] ?? '', // Added reporterName
      driverId: map['driverId'] ?? '',
      severity: map['severity'] ?? '',
      status: map['status'] ?? '',
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.parse(map['timestamp']),
      isFixed: map['isFixed'] ?? false,
    );
  }
}