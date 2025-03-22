import 'package:cloud_firestore/cloud_firestore.dart';

class BusMalfunction {
  final String id;
  final String busId;
  final String driverId;
  final String issue;
  final String description;
  final String severity; // 'Low', 'Medium', 'High', 'Critical'
  final String status; // 'reported', 'in_progress', 'resolved'
  final DateTime timestamp;
  final DateTime? resolvedAt;

  BusMalfunction({
    required this.id,
    required this.busId,
    required this.driverId,
    required this.issue,
    required this.description,
    required this.severity,
    required this.status,
    required this.timestamp,
    this.resolvedAt,
  });

  factory BusMalfunction.fromMap(Map<String, dynamic> map) {
    return BusMalfunction(
      id: map['id'] as String,
      busId: map['busId'] as String,
      driverId: map['driverId'] as String,
      issue: map['issue'] as String,
      description: map['description'] as String,
      severity: map['severity'] as String,
      status: map['status'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'busId': busId,
      'driverId': driverId,
      'issue': issue,
      'description': description,
      'severity': severity,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }
}