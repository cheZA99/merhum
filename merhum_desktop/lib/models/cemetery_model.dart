class CemeteryModel {
  final int id;
  final String name;
  final String address;
  final int cityId;
  final String cityName;
  final int totalPlots;
  // occupiedPlots and availablePlots are derived from the gravesite list, not included in the API response
  final int occupiedPlots;
  final int availablePlots;
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
    this.latitude,
    this.longitude,
    required this.isActive,
  });

  double get occupancyPercentage =>
      totalPlots > 0 ? (occupiedPlots / totalPlots * 100) : 0;

  factory CemeteryModel.fromJson(Map<String, dynamic> json) {
    return CemeteryModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      cityId: json['cityId'] as int? ?? 0,
      cityName: json['cityName'] as String? ?? '',
      totalPlots: json['totalPlaces'] as int? ?? 0,
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
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
    );
  }
}
