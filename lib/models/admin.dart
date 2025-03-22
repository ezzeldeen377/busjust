import 'package:bus_just/models/user.dart';

enum AdminRole { superAdmin, routeManager }

class Admin extends UserModel {
  final AdminRole adminRole;
  final Permission permissions;

  Admin({
    required super.id,
    required super.fullName,
    required super.email,
    required this.adminRole,
    required this.permissions,
    super.phoneNumber,
    super.profilePicture,
  }) : super(role: UserRole.admin);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'adminRole': adminRole.toString(),
      'permissions': permissions.toMap(),
    });
    return map;
  }

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      email: map['email'] as String,
      adminRole: AdminRole.values.firstWhere(
        (role) => role.toString() == map['adminRole'],
        orElse: () => AdminRole.routeManager,
      ),
      permissions: Permission.fromMap(map['permissions'] as Map<String, dynamic>),
      phoneNumber: map['phoneNumber'] as String?,
      profilePicture: map['profilePicture'] as String?,
    );
  }
}
class Permission {
  final bool canUpdateRoutes;
  final bool canMonitorDrivers;
  final bool canManageUsers;

  const Permission({
    required this.canUpdateRoutes,
    required this.canMonitorDrivers,
    required this.canManageUsers,
  });

  Map<String, dynamic> toMap() {
    return {
      'canUpdateRoutes': canUpdateRoutes,
      'canMonitorDrivers': canMonitorDrivers,
      'canManageUsers': canManageUsers,
    };
  }

  factory Permission.fromMap(Map<String, dynamic> map) {
    return Permission(
      canUpdateRoutes: map['canUpdateRoutes'] as bool,
      canMonitorDrivers: map['canMonitorDrivers'] as bool,
      canManageUsers: map['canManageUsers'] as bool,
    );
  }
}