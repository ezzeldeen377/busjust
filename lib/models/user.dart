
enum UserRole { student, driver, admin }

class UserModel {
  final String id;
  final String? fullName;
  final String email;
  final String? phoneNumber;
  final String? profilePicture;
  final UserRole role;

  UserModel({
    required this.id,
    this.fullName,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.profilePicture,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePicture': profilePicture,
      'role': role.name,
    };
  }

factory UserModel.fromMap(Map<String, dynamic> map) {
  return UserModel(
    id: map['id'] as String,
    fullName: map['fullName'] as String?,
    email: map['email'] as String,
    role: UserRole.values.byName(map['role'] as String),
    phoneNumber: map['phoneNumber'] as String?,
    profilePicture: map['profilePicture'] as String?,
  );
}
}