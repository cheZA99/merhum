class AppointmentModel {
  final int id;
  final int deceasedId;
  final String deceasedFullName;
  final DateTime funeralDateTime;
  final int? mosqueId;
  final String? mosqueName;
  final String? mosqueAddress;
  final double? mosqueLatitude;
  final double? mosqueLongitude;
  final int? imamId;
  final String? imamName;
  final int? cemeteryId;
  final String? cemeteryName;
  final int? graveSiteId;
  final String? graveSiteNumber;
  final String? notes;
  final String? contactPerson;
  final String? contactPhone;

  AppointmentModel({
    required this.id,
    required this.deceasedId,
    required this.deceasedFullName,
    required this.funeralDateTime,
    this.mosqueId,
    this.mosqueName,
    this.mosqueAddress,
    this.mosqueLatitude,
    this.mosqueLongitude,
    this.imamId,
    this.imamName,
    this.cemeteryId,
    this.cemeteryName,
    this.graveSiteId,
    this.graveSiteNumber,
    this.notes,
    this.contactPerson,
    this.contactPhone,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> j) => AppointmentModel(
        id: j['id'] as int,
        deceasedId: j['deceasedId'] as int,
        deceasedFullName: j['deceasedFullName'] as String? ?? '',
        funeralDateTime: DateTime.parse(j['funeralDateTime'] as String),
        mosqueId: j['mosqueId'] as int?,
        mosqueName: j['mosqueName'] as String?,
        mosqueAddress: j['mosqueAddress'] as String?,
        mosqueLatitude: (j['mosqueLatitude'] as num?)?.toDouble(),
        mosqueLongitude: (j['mosqueLongitude'] as num?)?.toDouble(),
        imamId: j['imamId'] as int?,
        imamName: j['imamFullName'] as String?,
        cemeteryId: j['cemeteryId'] as int?,
        cemeteryName: j['cemeteryName'] as String?,
        graveSiteId: j['graveSiteId'] as int?,
        graveSiteNumber: j['gravePlotNumber'] as String?,
        notes: j['note'] as String?,
        contactPerson: j['contactPersonName'] as String?,
        contactPhone: j['contactPersonPhone'] as String?,
      );
}
