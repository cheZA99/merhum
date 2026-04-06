class ImamModel {
  final int id;
  final String firstName;
  final String lastName;
  final int mosqueId;
  final String mosqueName;
  final String phone;
  final String? email;
  final bool isActive;
  final int appointmentCount; // not in backend yet, defaults to 0

  String get fullName => '$firstName $lastName';

  const ImamModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.mosqueId,
    required this.mosqueName,
    required this.phone,
    this.email,
    required this.isActive,
    this.appointmentCount = 0,
  });

  factory ImamModel.fromJson(Map<String, dynamic> json) {
    return ImamModel(
      id: json['id'] as int,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      mosqueId: json['mosqueId'] as int? ?? 0,
      mosqueName: json['mosqueName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      appointmentCount: 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'mosqueId': mosqueId,
        'phone': phone,
        'email': email,
        'isActive': isActive,
      };

  ImamModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    int? mosqueId,
    String? mosqueName,
    String? phone,
    String? email,
    bool? isActive,
    int? appointmentCount,
  }) {
    return ImamModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      mosqueId: mosqueId ?? this.mosqueId,
      mosqueName: mosqueName ?? this.mosqueName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      appointmentCount: appointmentCount ?? this.appointmentCount,
    );
  }
}
