class CemeterySectorModel {
  final int id;
  final String name;
  final int cemeteryId;
  // Not in backend response — enriched client-side by matching with cemeteries list
  final String cemeteryName;

  const CemeterySectorModel({
    required this.id,
    required this.name,
    required this.cemeteryId,
    this.cemeteryName = '',
  });

  factory CemeterySectorModel.fromJson(Map<String, dynamic> json) {
    return CemeterySectorModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      cemeteryId: json['cemeteryId'] as int? ?? 0,
      cemeteryName: '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'cemeteryId': cemeteryId,
      };

  CemeterySectorModel copyWith({String? cemeteryName}) {
    return CemeterySectorModel(
      id: id,
      name: name,
      cemeteryId: cemeteryId,
      cemeteryName: cemeteryName ?? this.cemeteryName,
    );
  }
}
