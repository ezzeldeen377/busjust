import 'package:bus_just/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Student extends UserModel {

  final String? selectedRouteId;
  final DateTime? lastUpdated;

  Student({
    required super.id,
    required super.fullName,
    required super.email,

    super.phoneNumber,
    super.profilePicture,
    this.selectedRouteId,
    this.lastUpdated,
  }) : super(role: UserRole.student);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({

      'selectedRouteId': selectedRouteId,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    });
    return map;
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      email: map['email'] as String,
      phoneNumber: map['phoneNumber'] as String?,
      profilePicture: map['profilePicture'] as String?,
      selectedRouteId: map['selectedRouteId'] as String?,
      lastUpdated: map['lastUpdated'] != null 
          ? (map['lastUpdated'] is Timestamp 
              ? (map['lastUpdated'] as Timestamp).toDate()
              : (map['lastUpdated'] as DateTime))
          : null,
    );
  }
}