class GraveSiteModel {
  final int id;
  final int cemeteryId;
  final String cemeteryName;
  final int? sectorId;
  final String? sectorName;
  final String plotNumber;
  final int? row;
  final String status;
  final int? deceasedId;
  final String? deceasedName;
  final String? qrCodeUrl;
  final double? latitude;
  final double? longitude;

  const GraveSiteModel({
    required this.id,
    required this.cemeteryId,
    required this.cemeteryName,
    this.sectorId,
    this.sectorName,
    required this.plotNumber,
    this.row,
    required this.status,
    this.deceasedId,
    this.deceasedName,
    this.qrCodeUrl,
    this.latitude,
    this.longitude,
  });

  factory GraveSiteModel.fromJson(Map<String, dynamic> json) {
    return GraveSiteModel(
      id: json['id'] as int,
      cemeteryId: json['cemeteryId'] as int? ?? 0,
      cemeteryName: json['cemeteryName'] as String? ?? '',
      sectorId: json['sectionId'] as int?,
      sectorName: json['sectionName'] as String?,
      plotNumber: json['plotNumber'] as String? ?? '',
      row: json['row'] as int?,
      status: json['status'] as String? ?? 'Slobodno',
      deceasedId: json['deceasedId'] as int?,
      deceasedName: json['deceasedFullName'] as String?,
      qrCodeUrl: json['qrCodeUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'cemeteryId': cemeteryId,
        'sectionId': sectorId,
        'plotNumber': plotNumber,
        'row': row,
        'latitude': latitude,
        'longitude': longitude,
      };

  GraveSiteModel copyWith({
    int? id,
    int? cemeteryId,
    String? cemeteryName,
    int? sectorId,
    String? sectorName,
    String? plotNumber,
    int? row,
    String? status,
    int? deceasedId,
    String? deceasedName,
    String? qrCodeUrl,
    double? latitude,
    double? longitude,
  }) {
    return GraveSiteModel(
      id: id ?? this.id,
      cemeteryId: cemeteryId ?? this.cemeteryId,
      cemeteryName: cemeteryName ?? this.cemeteryName,
      sectorId: sectorId ?? this.sectorId,
      sectorName: sectorName ?? this.sectorName,
      plotNumber: plotNumber ?? this.plotNumber,
      row: row ?? this.row,
      status: status ?? this.status,
      deceasedId: deceasedId ?? this.deceasedId,
      deceasedName: deceasedName ?? this.deceasedName,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
