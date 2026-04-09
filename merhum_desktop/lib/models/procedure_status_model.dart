class ProcedureStatusModel {
  final int id;
  final String name;
  final String? description;
  final int order;

  const ProcedureStatusModel({
    required this.id,
    required this.name,
    this.description,
    required this.order,
  });

  factory ProcedureStatusModel.fromJson(Map<String, dynamic> json) {
    return ProcedureStatusModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      order: json['sortOrder'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'sortOrder': order,
      };
}
