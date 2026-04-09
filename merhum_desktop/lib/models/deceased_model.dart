import 'status_history_model.dart';

class DeceasedModel {
  final int id;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final DateTime dateOfDeath;
  final String placeOfDeath;
  final String? photoUrl;
  final String contactPersonName;
  final String contactPersonPhone;
  final String? contactPersonEmail;
  final int cityId;
  final String cityName;
  final int procedureStatusId;
  final String procedureStatusName;
  final DateTime createdAt;
  final String createdByUsername;
  final String? obituarySlug;
  final List<StatusHistoryModel>? statusHistory;

  const DeceasedModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.dateOfDeath,
    required this.placeOfDeath,
    this.photoUrl,
    required this.contactPersonName,
    required this.contactPersonPhone,
    this.contactPersonEmail,
    required this.cityId,
    required this.cityName,
    required this.procedureStatusId,
    required this.procedureStatusName,
    required this.createdAt,
    required this.createdByUsername,
    this.obituarySlug,
    this.statusHistory,
  });

  String get fullName => '$firstName $lastName';

  int get ageAtDeath => dateOfDeath.year - dateOfBirth.year;

  factory DeceasedModel.fromJson(Map<String, dynamic> json) {
    return DeceasedModel(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      dateOfDeath: DateTime.parse(json['dateOfDeath'] as String),
      placeOfDeath: json['placeOfDeath'] as String,
      photoUrl: json['photoUrl'] as String?,
      contactPersonName: json['contactPersonName'] as String,
      contactPersonPhone: json['contactPersonPhone'] as String,
      contactPersonEmail: json['contactPersonEmail'] as String?,
      cityId: json['cityId'] as int? ?? 0,
      cityName: json['cityName'] as String? ?? '',
      procedureStatusId: json['procedureStatusId'] as int,
      procedureStatusName: json['procedureStatusName'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdByUsername: json['createdByUsername'] as String? ?? '',
      obituarySlug: json['obituarySlug'] as String?,
      statusHistory: null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth.toIso8601String().split('T')[0],
        'dateOfDeath': dateOfDeath.toIso8601String().split('T')[0],
        'placeOfDeath': placeOfDeath,
        'photoUrl': photoUrl,
        'contactPersonName': contactPersonName,
        'contactPersonPhone': contactPersonPhone,
        'contactPersonEmail': contactPersonEmail,
        'cityId': cityId,
        'cityName': cityName,
        'procedureStatusId': procedureStatusId,
        'procedureStatusName': procedureStatusName,
        'createdAt': createdAt.toIso8601String(),
        'createdByUsername': createdByUsername,
        'obituarySlug': obituarySlug,
      };

  DeceasedModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    DateTime? dateOfDeath,
    String? placeOfDeath,
    String? photoUrl,
    String? contactPersonName,
    String? contactPersonPhone,
    String? contactPersonEmail,
    int? cityId,
    String? cityName,
    int? procedureStatusId,
    String? procedureStatusName,
    DateTime? createdAt,
    String? createdByUsername,
    String? obituarySlug,
    List<StatusHistoryModel>? statusHistory,
  }) {
    return DeceasedModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      dateOfDeath: dateOfDeath ?? this.dateOfDeath,
      placeOfDeath: placeOfDeath ?? this.placeOfDeath,
      photoUrl: photoUrl ?? this.photoUrl,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      contactPersonPhone: contactPersonPhone ?? this.contactPersonPhone,
      contactPersonEmail: contactPersonEmail ?? this.contactPersonEmail,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      procedureStatusId: procedureStatusId ?? this.procedureStatusId,
      procedureStatusName: procedureStatusName ?? this.procedureStatusName,
      createdAt: createdAt ?? this.createdAt,
      createdByUsername: createdByUsername ?? this.createdByUsername,
      obituarySlug: obituarySlug ?? this.obituarySlug,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }
}
