class DeceasedModel {
  final int id;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final DateTime dateOfDeath;
  final String? placeOfDeath;
  final int? cityId;
  final String? cityName;
  final String? photoUrl;
  final String? contactPerson;
  final String? contactPhone;
  final String? contactEmail;
  final int? procedureStatusId;
  final String? procedureStatusName;

  DeceasedModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    required this.dateOfDeath,
    this.placeOfDeath,
    this.cityId,
    this.cityName,
    this.photoUrl,
    this.contactPerson,
    this.contactPhone,
    this.contactEmail,
    this.procedureStatusId,
    this.procedureStatusName,
  });

  String get fullName => '$firstName $lastName';

  factory DeceasedModel.fromJson(Map<String, dynamic> j) => DeceasedModel(
        id: j['id'] as int,
        firstName: j['firstName'] as String? ?? '',
        lastName: j['lastName'] as String? ?? '',
        dateOfBirth: j['dateOfBirth'] != null ? DateTime.parse(j['dateOfBirth']) : null,
        dateOfDeath: DateTime.parse(j['dateOfDeath'] as String),
        placeOfDeath: j['placeOfDeath'] as String?,
        cityId: j['cityId'] as int?,
        cityName: j['cityName'] as String?,
        photoUrl: j['photoUrl'] as String?,
        contactPerson: j['contactPerson'] as String?,
        contactPhone: j['contactPhone'] as String?,
        contactEmail: j['contactEmail'] as String?,
        procedureStatusId: j['procedureStatusId'] as int?,
        procedureStatusName: j['procedureStatusName'] as String?,
      );
}
