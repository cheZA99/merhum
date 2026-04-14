class UserModel {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String role;
  final String? cityName;
  final bool isConfirmed;
  final bool isLocked;
  final DateTime registeredAt;

  String get fullName => '$firstName $lastName'.trim();

  const UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.role,
    this.cityName,
    required this.isConfirmed,
    required this.isLocked,
    required this.registeredAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? '',
      cityName: json['cityName'] as String?,
      isConfirmed: json['isConfirmed'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
      registeredAt: DateTime.parse(json['registeredAt'] as String),
    );
  }

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? role,
    String? cityName,
    bool? isConfirmed,
    bool? isLocked,
  }) {
    return UserModel(
      id: id,
      username: username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      cityName: cityName ?? this.cityName,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isLocked: isLocked ?? this.isLocked,
      registeredAt: registeredAt,
    );
  }
}
