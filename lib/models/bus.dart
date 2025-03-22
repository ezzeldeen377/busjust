class Bus {
  final String id;
  final String? registrationNumber;
  final int? capacity;
  final bool? isActive;
  final String? currentDriverId;
  final String? currentTripId;

  Bus({
    required this.id,
    this.registrationNumber,
    this.capacity,
    this.isActive = true,
    this.currentDriverId,
    this.currentTripId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'registrationNumber': registrationNumber,
      'capacity': capacity,
      'isActive': isActive,
      'currentDriverId': currentDriverId,
      'currentTripId': currentTripId,
    };
  }

  factory Bus.fromMap(Map<String, dynamic> map) {
    return Bus(
      id: map['id'],
      registrationNumber: map['registrationNumber'],
      capacity: map['capacity'],
      isActive: map['isActive'] ?? true,
      currentDriverId: map['currentDriverId'],
      currentTripId: map['currentTripId'],
    );
  }
}