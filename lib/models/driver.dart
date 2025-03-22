import 'package:bus_just/models/user.dart';

enum WorkStatus { online, offline }

class Driver extends UserModel {
  final String? assignedBus;
  final WorkStatus? workStatus;
  final String? licenseNumber;

  Driver({
    required super.id,
    required super.fullName,
    required super.email,
    required  super.phoneNumber,
    this.assignedBus,
     this.workStatus,
    this.licenseNumber,
    super.profilePicture,
  }) : super(role: UserRole.driver);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'assignedBus': assignedBus,
      'workStatus': workStatus.toString(),
      'licenseNumber': licenseNumber,
    });
    return map;
  }

  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['id'] as String,
      fullName: map['fullName'] as String?,
      email: map['email'] as String,
      phoneNumber: map['phoneNumber'] as String?,
      assignedBus: map['assignedBus'] as String?,
      workStatus: WorkStatus.values.firstWhere(
        (status) => status.toString() == map['workStatus'],
        orElse: () => WorkStatus.offline,
      ),
      licenseNumber: map['licenseNumber'] as String?,
      profilePicture: map['profilePicture'] as String?,
    );
  }
}