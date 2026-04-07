class CityModel {
  final int id;
  final String name;
  final String? postalCode;
  final int countryId;
  final String countryName;

  const CityModel({
    required this.id,
    required this.name,
    this.postalCode,
    required this.countryId,
    required this.countryName,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      postalCode: json['postalCode'] as String?,
      countryId: json['countryId'] as int? ?? 0,
      countryName: json['countryName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'postalCode': postalCode,
        'countryId': countryId,
      };
}
