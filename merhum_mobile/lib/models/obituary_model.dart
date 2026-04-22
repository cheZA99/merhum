class ObituaryModel {
  final int id;
  final String uniqueSlug;
  final int deceasedId;
  final String deceasedFullName;
  final DateTime? dateOfBirth;
  final DateTime dateOfDeath;
  final String? cityName;
  final String? photoUrl;
  final String? inMemoriam;
  final bool isPublic;
  final bool isActive;
  final int viewCount;
  final int condolenceCount;
  final DateTime createdAt;

  ObituaryModel({
    required this.id,
    required this.uniqueSlug,
    required this.deceasedId,
    required this.deceasedFullName,
    this.dateOfBirth,
    required this.dateOfDeath,
    this.cityName,
    this.photoUrl,
    this.inMemoriam,
    required this.isPublic,
    required this.isActive,
    required this.viewCount,
    required this.condolenceCount,
    required this.createdAt,
  });

  factory ObituaryModel.fromJson(Map<String, dynamic> j) => ObituaryModel(
        id: j['id'] as int,
        uniqueSlug: j['uniqueSlug'] as String? ?? '',
        deceasedId: j['deceasedId'] as int,
        deceasedFullName: j['deceasedFullName'] as String? ?? '',
        dateOfBirth: j['dateOfBirth'] != null ? DateTime.parse(j['dateOfBirth']) : null,
        dateOfDeath: DateTime.parse(j['dateOfDeath'] as String),
        cityName: j['cityName'] as String?,
        photoUrl: j['photoUrl'] as String?,
        inMemoriam: j['inMemoriam'] as String?,
        isPublic: j['isPublic'] as bool? ?? true,
        isActive: j['isActive'] as bool? ?? true,
        viewCount: j['viewCount'] as int? ?? 0,
        condolenceCount: j['condolenceCount'] as int? ?? 0,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
