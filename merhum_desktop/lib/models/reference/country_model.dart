class CountryModel {
  final int id;
  final String name;
  final String code;

  const CountryModel({
    required this.id,
    required this.name,
    required this.code,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
      };
}
