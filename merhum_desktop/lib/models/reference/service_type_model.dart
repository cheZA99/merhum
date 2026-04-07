class ServiceTypeModel {
  final int id;
  final String name;
  final String? description;

  const ServiceTypeModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory ServiceTypeModel.fromJson(Map<String, dynamic> json) {
    return ServiceTypeModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
      };
}
