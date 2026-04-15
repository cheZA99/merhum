class CemeteryModel {
  final int id;
  final String name;
  final String address;
  final int cityId;
  final String cityName;
  final int totalPlots;
  final int occupiedPlots;
  final int availablePlots;
  final int reservedPlots;
  final double fillPercentage;
  final double? latitude;
  final double? longitude;
  final bool isActive;

  const CemeteryModel({
    required this.id,
    required this.name,
    required this.address,
    required this.cityId,
    required this.cityName,
    required this.totalPlots,
    this.occupiedPlots = 0,
    this.availablePlots = 0,
    this.reservedPlots = 0,
    this.fillPercentage = 0.0,
    this.latitude,
    this.longitude,
    required this.isActive,
  });

  double get occupancyPercentage => fillPercentage;

  factory CemeteryModel.fromJson(Map<String, dynamic> json) {
    return CemeteryModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      cityId: json['cityId'] as int? ?? 0,
      cityName: json['cityName'] as String? ?? '',
      totalPlots: json['totalPlaces'] as int? ?? 0,
      occupiedPlots: json['occupiedPlaces'] as int? ?? 0,
      availablePlots: json['availablePlaces'] as int? ?? 0,
      reservedPlots: json['reservedPlaces'] as int? ?? 0,
      fillPercentage: (json['fillPercentage'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'cityId': cityId,
        'totalPlaces': totalPlots,
        'latitude': latitude,
        'longitude': longitude,
        'isActive': isActive,
      };

  CemeteryModel copyWith({
    int? id,
    String? name,
    String? address,
    int? cityId,
    String? cityName,
    int? totalPlots,
    int? occupiedPlots,
    int? availablePlots,
    int? reservedPlots,
    double? fillPercentage,
    double? latitude,
    double? longitude,
    bool? isActive,
  }) {
    return CemeteryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      totalPlots: totalPlots ?? this.totalPlots,
      occupiedPlots: occupiedPlots ?? this.occupiedPlots,
      availablePlots: availablePlots ?? this.availablePlots,
      reservedPlots: reservedPlots ?? this.reservedPlots,
      fillPercentage: fillPercentage ?? this.fillPercentage,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
    );
  }
}
