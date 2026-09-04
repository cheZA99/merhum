class GraveSiteModel {
  final int id;
  final int cemeteryId;
  final String cemeteryName;
  final String? sectionName;
  final String plotNumber;
  final int? row;
  final String status;
  final int? deceasedId;
  final String? deceasedFullName;
  final double? latitude;
  final double? longitude;

  GraveSiteModel({
    required this.id,
    required this.cemeteryId,
    required this.cemeteryName,
    required this.plotNumber,
    required this.status,
    this.sectionName,
    this.row,
    this.deceasedId,
    this.deceasedFullName,
    this.latitude,
    this.longitude,
  });

  factory GraveSiteModel.fromJson(Map<String, dynamic> j) => GraveSiteModel(
        id: j['id'] as int,
        cemeteryId: j['cemeteryId'] as int,
        cemeteryName: j['cemeteryName'] as String? ?? '',
        sectionName: j['sectionName'] as String?,
        plotNumber: j['plotNumber'] as String? ?? '',
        row: j['row'] as int?,
        status: j['status'] as String? ?? '',
        deceasedId: j['deceasedId'] as int?,
        deceasedFullName: j['deceasedFullName'] as String?,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
      );
}
