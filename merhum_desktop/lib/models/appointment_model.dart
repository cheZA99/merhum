class AppointmentModel {
  final int id;
  final int deceasedId;
  final String deceasedFullName;
  final int mosqueId;
  final String mosqueName;
  final int cemeteryId;
  final String cemeteryName;
  final int? imamId;
  final String? imamFullName;
  final int? graveSiteId;
  final String? gravePlotNumber;
  final DateTime funeralDateTime;
  final String status;
  final String? note;
  final DateTime createdAt;

  const AppointmentModel({
    required this.id,
    required this.deceasedId,
    required this.deceasedFullName,
    required this.mosqueId,
    required this.mosqueName,
    required this.cemeteryId,
    required this.cemeteryName,
    this.imamId,
    this.imamFullName,
    this.graveSiteId,
    this.gravePlotNumber,
    required this.funeralDateTime,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as int,
      deceasedId: json['deceasedId'] as int,
      deceasedFullName: json['deceasedFullName'] as String? ?? '',
      mosqueId: json['mosqueId'] as int,
      mosqueName: json['mosqueName'] as String? ?? '',
      cemeteryId: json['cemeteryId'] as int,
      cemeteryName: json['cemeteryName'] as String? ?? '',
      imamId: json['imamId'] as int?,
      imamFullName: json['imamFullName'] as String?,
      graveSiteId: json['graveSiteId'] as int?,
      gravePlotNumber: json['gravePlotNumber'] as String?,
      funeralDateTime: DateTime.parse(json['funeralDateTime'] as String),
      status: json['status'] as String? ?? '',
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'deceasedId': deceasedId,
        'mosqueId': mosqueId,
        'cemeteryId': cemeteryId,
        'imamId': imamId,
        'graveSiteId': graveSiteId,
        'funeralDateTime': funeralDateTime.toIso8601String(),
        'note': note,
      };

  AppointmentModel copyWith({
    int? id,
    int? deceasedId,
    String? deceasedFullName,
    int? mosqueId,
    String? mosqueName,
    int? cemeteryId,
    String? cemeteryName,
    int? imamId,
    String? imamFullName,
    int? graveSiteId,
    String? gravePlotNumber,
    DateTime? funeralDateTime,
    String? status,
    String? note,
    DateTime? createdAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      deceasedId: deceasedId ?? this.deceasedId,
      deceasedFullName: deceasedFullName ?? this.deceasedFullName,
      mosqueId: mosqueId ?? this.mosqueId,
      mosqueName: mosqueName ?? this.mosqueName,
      cemeteryId: cemeteryId ?? this.cemeteryId,
      cemeteryName: cemeteryName ?? this.cemeteryName,
      imamId: imamId ?? this.imamId,
      imamFullName: imamFullName ?? this.imamFullName,
      graveSiteId: graveSiteId ?? this.graveSiteId,
      gravePlotNumber: gravePlotNumber ?? this.gravePlotNumber,
      funeralDateTime: funeralDateTime ?? this.funeralDateTime,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
