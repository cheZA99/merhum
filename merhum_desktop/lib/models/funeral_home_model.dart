class FuneralHomeModel {
  final int id;
  final String name;
  final String address;
  final int cityId;
  final String cityName;
  final String phone;
  final String? email;
  final String? licenseNumber;
  final bool isActive;
  final int activeOrdersCount; // not in backend yet, defaults to 0

  const FuneralHomeModel({
    required this.id,
    required this.name,
    required this.address,
    required this.cityId,
    required this.cityName,
    required this.phone,
    this.email,
    this.licenseNumber,
    required this.isActive,
    this.activeOrdersCount = 0,
  });

  factory FuneralHomeModel.fromJson(Map<String, dynamic> json) {
    return FuneralHomeModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      cityId: json['cityId'] as int? ?? 0,
      cityName: json['cityName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      activeOrdersCount: 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'cityId': cityId,
        'phone': phone,
        'email': email,
        'licenseNumber': licenseNumber,
        'isActive': isActive,
      };

  FuneralHomeModel copyWith({
    int? id,
    String? name,
    String? address,
    int? cityId,
    String? cityName,
    String? phone,
    String? email,
    String? licenseNumber,
    bool? isActive,
    int? activeOrdersCount,
  }) {
    return FuneralHomeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      isActive: isActive ?? this.isActive,
      activeOrdersCount: activeOrdersCount ?? this.activeOrdersCount,
    );
  }
}
