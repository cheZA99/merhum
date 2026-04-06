class MosqueModel {
  final int id;
  final String name;
  final String address;
  final int cityId;
  final String cityName;
  final String? phone;
  final String? email;
  final int? capacity;
  final double? latitude;
  final double? longitude;
  final bool isActive;

  const MosqueModel({
    required this.id,
    required this.name,
    required this.address,
    required this.cityId,
    required this.cityName,
    this.phone,
    this.email,
    this.capacity,
    this.latitude,
    this.longitude,
    required this.isActive,
  });

  factory MosqueModel.fromJson(Map<String, dynamic> json) {
    return MosqueModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      cityId: json['cityId'] as int? ?? 0,
      cityName: json['cityName'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      capacity: json['capacity'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'cityId': cityId,
        'phone': phone,
        'email': email,
        'capacity': capacity,
        'latitude': latitude,
        'longitude': longitude,
        'isActive': isActive,
      };

  MosqueModel copyWith({
    int? id,
    String? name,
    String? address,
    int? cityId,
    String? cityName,
    String? phone,
    String? email,
    int? capacity,
    double? latitude,
    double? longitude,
    bool? isActive,
  }) {
    return MosqueModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      capacity: capacity ?? this.capacity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
    );
  }
}
