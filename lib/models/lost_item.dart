// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';


class LostItem {
  final String id;
  final String studentId;
  final String? tripId;
  final String? busId;
  final String itemName;
  final DateTime reportDate;
  final String? reporterName;
  final String description;
  final String status; // 'pending', 'found', 'claimed'
  final String? imageUrl;

  LostItem({
    required this.id,
    required this.studentId,
    this.tripId,
    this.busId,
    required this.itemName,
    required this.reportDate,
    this.reporterName,
    required this.description,
    required this.status,
    this.imageUrl,
  });

  factory LostItem.fromMap(Map<String, dynamic> map) {
    return LostItem(
      id: map['id'] as String,
      studentId: map['studentId'] as String,
      tripId: map['tripId'] != null ? map['tripId'] as String : null,
      busId: map['busId'] != null ? map['busId'] as String : null,
      itemName: map['itemName'] as String,
      reportDate: map['reportDate'] is Timestamp 
          ? (map['reportDate'] as Timestamp).toDate()
          : map['reportDate'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(map['reportDate'])
              : DateTime.parse(map['reportDate'].toString()),
      reporterName: map['reporterName'] != null ? map['reporterName'] as String : null,
      description: map['description'] as String,
      status: map['status'] as String,
      imageUrl: map['imageUrl'] != null ? map['imageUrl'] as String : null,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'studentId': studentId,
      'tripId': tripId,
      'busId': busId,
      'itemName': itemName,
      'reportDate': reportDate,
      'reporterName': reporterName,
      'description': description,
      'status': status,
      'imageUrl': imageUrl,
    };
  }

  LostItem copyWith({
    String? id,
    String? studentId,
    String? tripId,
    String? busId,
    String? itemName,
    DateTime? reportDate,
    String? reporterName,
    String? description,
    String? status,
    String? imageUrl,
  }) {
    return LostItem(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      tripId: tripId ?? this.tripId,
      busId: busId ?? this.busId,
      itemName: itemName ?? this.itemName,
      reportDate: reportDate ?? this.reportDate,
      reporterName: reporterName ?? this.reporterName,
      description: description ?? this.description,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  String toJson() => json.encode(toMap());

  factory LostItem.fromJson(String source) => LostItem.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'LostItem(id: $id, studentId: $studentId, tripId: $tripId, busId: $busId, itemName: $itemName, reportDate: $reportDate, reporterName: $reporterName, description: $description, status: $status, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(covariant LostItem other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.studentId == studentId &&
      other.tripId == tripId &&
      other.busId == busId &&
      other.itemName == itemName &&
      other.reportDate == reportDate &&
      other.reporterName == reporterName &&
      other.description == description &&
      other.status == status &&
      other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      studentId.hashCode ^
      tripId.hashCode ^
      busId.hashCode ^
      itemName.hashCode ^
      reportDate.hashCode ^
      reporterName.hashCode ^
      description.hashCode ^
      status.hashCode ^
      imageUrl.hashCode;
  }
}
